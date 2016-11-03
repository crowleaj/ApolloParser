# Apollo Grammar

## Comments (comment)
Comments follow the traditional C-style syntax and allow for block or line comments.
### Line comment
    "//" * (? - "\n")^0 * "\n"
### Block comment
```
"/*" * (? - "*/")^0 * "*/"
```

## Constants (const)
A constant consists of a number or a string.

### Integer (int)
```
"-"^-1 * R[09]^1
```
### Float (float)
```
"-"^-1 * ((R[09]^1 * ("." * R[09]^0)) +
(R[09]^0 * ("." * R[09]^1)))
```
### Number (num)
```
int + float
```
### String (string)
```
("'" * (? - "'") * "'") +
('"' * (? - '"') * '"')
```
## Identifiers
Identifiers are used to assign values and perform operations with.
### Variable (var)
```
  ("_" + R[az, AZ]) * ("_" + R[az, AZ, 09])^0
```
