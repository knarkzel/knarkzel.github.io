use anyhow::{anyhow, Result};
use nom::{
    branch::alt,
    bytes::complete::tag,
    character::complete::{digit1, multispace0},
    combinator::map,
    multi::many1,
    sequence::delimited,
    IResult,
};
use rustyline::{error::ReadlineError, Editor};

// Parser
#[derive(Debug)]
enum Operator {
    Plus,
    Minus,
    Divide,
    Multiply,
}

#[derive(Debug)]
enum Atom {
    Number(isize),
    Operator(Operator),
}

fn operator(input: &str) -> IResult<&str, Atom> {
    let plus = map(tag("+"), |_| Operator::Plus);
    let minus = map(tag("-"), |_| Operator::Minus);
    let divide = map(tag("/"), |_| Operator::Divide);
    let multiply = map(tag("*"), |_| Operator::Multiply);
    map(alt((plus, minus, divide, multiply)), Atom::Operator)(input)
}

fn number(input: &str) -> IResult<&str, Atom> {
    map(digit1, |digits: &str| {
        Atom::Number(digits.parse::<isize>().unwrap())
    })(input)
}

fn atom(input: &str) -> IResult<&str, Atom> {
    let options = alt((operator, number));
    delimited(multispace0, options, multispace0)(input)
}

fn parse(input: &str) -> IResult<&str, Vec<Atom>> {
    delimited(tag("("), many1(atom), tag(")"))(input)
}

// Helpers
fn atoms_to_numbers(atoms: &[Atom]) -> Result<Vec<isize>> {
    let numbers = atoms
        .iter()
        .map(|atom| match atom {
            Atom::Number(number) => Ok(*number),
            atom => Err(anyhow!("Expected number, got {atom:?}")),
        })
        .collect::<Result<Vec<_>, _>>()?;
    Ok(numbers)
}

// Evaluator
fn eval(atoms: &[Atom]) -> Result<Atom> {
    match atoms {
        [Atom::Operator(operator), tail @ ..] => {
            let numbers = atoms_to_numbers(tail)?;
            let total = numbers
                .into_iter()
                .reduce(|total, number| match operator {
                    Operator::Plus => total + number,
                    Operator::Minus => total - number,
                    Operator::Divide => total / number,
                    Operator::Multiply => total * number,
                })
                .ok_or_else(|| anyhow!("Tail is empty"))?;
            Ok(Atom::Number(total))
        }
        atoms => Err(anyhow!("Invalid input: {atoms:#?}")),
    }
}

fn main() -> Result<()> {
    let mut editor = Editor::<()>::new()?;
    loop {
        match editor.readline(">> ") {
            Ok(input) => match parse(&input) {
                Ok((_, atoms)) => {
                    let output = eval(&atoms)?;
                    println!("{output:?}");
                }
                Err(error) => println!("{error}"),
            },
            Err(ReadlineError::Interrupted | ReadlineError::Eof) => break,
            Err(error) => {
                println!("Error: {error}");
                break;
            }
        }
    }
    Ok(())
}
