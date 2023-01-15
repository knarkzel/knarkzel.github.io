use anyhow::{anyhow, Result};
use nom::{
    branch::alt,
    bytes::complete::tag,
    character::complete::{digit1, multispace0},
    combinator::map,
    multi::many1,
    sequence::{delimited, preceded},
    IResult,
};

// Parser
#[derive(Debug)]
enum Atom {
    Plus,
    Minus,
    Divide,
    Multiply,
    Number(isize),
}

fn builtin(input: &str) -> IResult<&str, Atom> {
    let plus = map(tag("+"), |_| Atom::Plus);
    let minus = map(tag("-"), |_| Atom::Minus);
    let divide = map(tag("/"), |_| Atom::Divide);
    let multiply = map(tag("*"), |_| Atom::Multiply);
    alt((plus, minus, divide, multiply))(input)
}

fn number(input: &str) -> IResult<&str, Atom> {
    map(digit1, |digits: &str| {
        Atom::Number(digits.parse::<isize>().unwrap())
    })(input)
}

fn atom(input: &str) -> IResult<&str, Atom> {
    let options = alt((builtin, number));
    delimited(multispace0, options, multispace0)(input)
}

fn parse(input: &str) -> IResult<&str, Vec<Atom>> {
    delimited(tag("("), preceded(multispace0, many1(atom)), tag(")"))(input)
}

// Helpers
fn atoms_to_numbers(atoms: &[Atom]) -> Result<Vec<isize>> {
    let numbers = atoms
        .into_iter()
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
        [Atom::Plus, tail @ ..] => {
            let numbers = atoms_to_numbers(tail)?;
            let total = numbers
                .into_iter()
                .reduce(|acc, number| acc + number)
                .ok_or(anyhow!("Tail is empty"))?;
            Ok(Atom::Number(total))
        }
        [Atom::Minus, tail @ ..] => {
            let numbers = atoms_to_numbers(tail)?;
            let total = numbers
                .into_iter()
                .reduce(|acc, number| acc - number)
                .ok_or(anyhow!("Tail is empty"))?;
            Ok(Atom::Number(total))
        }
        [Atom::Divide, tail @ ..] => {
            let numbers = atoms_to_numbers(tail)?;
            let total = numbers
                .into_iter()
                .reduce(|acc, number| acc / number)
                .ok_or(anyhow!("Tail is empty"))?;
            Ok(Atom::Number(total))
        }
        [Atom::Multiply, tail @ ..] => {
            let numbers = atoms_to_numbers(tail)?;
            let total = numbers
                .into_iter()
                .reduce(|acc, number| acc * number)
                .ok_or(anyhow!("Tail is empty"))?;
            Ok(Atom::Number(total))
        }
        atoms => Err(anyhow!("Invalid pattern: {atoms:#?}")),
    }
}

fn main() -> Result<()> {
    let input = "(+ 1 2 3 4 5)";
    let (_, atoms) = parse(input)?;
    let output = eval(&atoms)?;
    println!("{output:?}");
    Ok(())
}