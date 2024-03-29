use anyhow::{anyhow, Result};
use nom::{
    branch::alt,
    bytes::complete::tag,
    character::complete::{alpha1, digit1, multispace0, multispace1},
    combinator::map,
    multi::{many0, many1},
    sequence::{delimited, pair, preceded, separated_pair, terminated},
    IResult,
};
use rustyline::{error::ReadlineError, validate::MatchingBracketValidator, Editor};
use rustyline_derive::{Completer, Helper, Highlighter, Hinter, Validator};
use std::collections::HashMap;

// Parser
#[derive(Debug, Clone)]
enum Operator {
    Plus,
    Minus,
    Divide,
    Multiply,
}

#[derive(Debug, Clone)]
enum Atom {
    Number(isize),
    Operator(Operator),
    Symbol(String),
}

// Atom
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

fn symbol(input: &str) -> IResult<&str, Atom> {
    map(alpha1, |name: &str| Atom::Symbol(name.to_string()))(input)
}

fn atom(input: &str) -> IResult<&str, Atom> {
    let options = alt((symbol, operator, number));
    delimited(multispace0, options, multispace0)(input)
}

// Expr
#[derive(Debug, Clone)]
enum Expr {
    Constant(Atom),
    Define(Atom, Box<Expr>),
    Call(Box<Expr>, Vec<Expr>),
    Lambda(Vec<Atom>, Box<Expr>),
    Nil,
}

fn constant(input: &str) -> IResult<&str, Expr> {
    map(atom, Expr::Constant)(input)
}

fn call(input: &str) -> IResult<&str, Expr> {
    let form = pair(expr, many0(expr));
    let call = map(form, |(head, tail)| Expr::Call(Box::new(head), tail));
    delimited(tag("("), call, tag(")"))(input)
}

fn define(input: &str) -> IResult<&str, Expr> {
    let form = preceded(tag("define"), pair(atom, expr));
    let define = map(form, |(name, value)| Expr::Define(name, Box::new(value)));
    delimited(tag("("), define, tag(")"))(input)
}

fn lambda(input: &str) -> IResult<&str, Expr> {
    let args = delimited(tag("("), many0(atom), tag(")"));
    let form = preceded(
        terminated(tag("lambda"), multispace1),
        separated_pair(args, multispace1, expr),
    );
    let lambda = map(form, |(args, body)| Expr::Lambda(args, Box::new(body)));
    delimited(tag("("), lambda, tag(")"))(input)
}

fn expr(input: &str) -> IResult<&str, Expr> {
    alt((define, call, lambda, constant))(input)
}

// Final parser
fn parse(input: &str) -> IResult<&str, Vec<Expr>> {
    many1(delimited(multispace0, expr, multispace0))(input)
}

// Helpers
fn exprs_to_numbers(exprs: &[Expr]) -> Result<Vec<isize>> {
    let numbers = exprs
        .iter()
        .map(|expr| match expr {
            Expr::Constant(Atom::Number(number)) => Ok(*number),
            atom => Err(anyhow!("Expected number, got {atom:?}")),
        })
        .collect::<Result<Vec<_>, _>>()?;
    Ok(numbers)
}

// Evaluator
fn eval(expr: Expr, environment: &mut HashMap<String, Expr>) -> Result<Expr> {
    let output = match expr {
        Expr::Constant(Atom::Symbol(name)) => environment
            .get(&name)
            .ok_or_else(|| anyhow!("`{name}` is not defined"))?
            .clone(),
        Expr::Define(Atom::Symbol(name), value) => {
            let value = eval(*value, environment)?;
            environment.insert(name, value);
            Expr::Nil
        }
        Expr::Call(head, tail) => {
            let head = eval(*head, environment)?;
            let tail = tail
                .into_iter()
                .map(|expr| eval(expr, environment))
                .collect::<Result<Vec<_>, _>>()?;
            match head {
                Expr::Constant(Atom::Operator(operator)) => {
                    let numbers = exprs_to_numbers(&tail)?;
                    let total = numbers
                        .into_iter()
                        .reduce(|total, number| match operator {
                            Operator::Plus => total + number,
                            Operator::Minus => total - number,
                            Operator::Divide => total / number,
                            Operator::Multiply => total * number,
                        })
                        .ok_or_else(|| anyhow!("Tail is empty"))?;
                    Expr::Constant(Atom::Number(total))
                }
                Expr::Lambda(args, body) => {
                    let scope = environment.clone();
                    for (arg, expr) in args.into_iter().zip(tail.into_iter()) {
                        match arg {
                            Atom::Symbol(name) => {
                                environment.insert(name, expr);
                            }
                            _ => return Err(anyhow!("Invalid symbol: {arg:?}")),
                        }
                    }
                    let output = eval(*body, environment)?;
                    *environment = scope;
                    output
                }
                _ => return Err(anyhow!("Invalid function: {head:?}")),
            }
        }
        Expr::Lambda(_, _) | Expr::Constant(_) | Expr::Nil => expr,
        _ => return Err(anyhow!("Invalid expression: {expr:?}")),
    };
    Ok(output)
}

// Rustyline
#[derive(Helper, Completer, Hinter, Validator, Highlighter)]
struct Helper {
    #[rustyline(Validator)]
    validator: MatchingBracketValidator,
}

fn main() -> Result<()> {
    // Create rustyline editor
    let mut editor = Editor::new()?;
    let helper = Helper {
        validator: MatchingBracketValidator::new(),
    };
    editor.set_helper(Some(helper));

    // Read lines and eval them
    let mut environment = HashMap::new();
    loop {
        match editor.readline(">> ") {
            Ok(input) => match parse(&input) {
                Ok((_, exprs)) => {
                    for expr in exprs {
                        let output = eval(expr, &mut environment)?;
                        println!("{output:?}");
                    }
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
