# 用yacc和lex实现计算器
```
./mycalc
1+1
>>2
2+5*3
>>17.000000
1/0
>>inf
```

# 计算器
古老的yacc/lex，可以用GNU 版的bison和flex代替。
一般编程语言的语法处理，都会有以下的过程。

yacc 是“Yet.Another.Compiler.Compiler”的缩写。顾名思义， Compiler.Compiler就是生成编译器的编译器。
lex则只是简单地取自 lexical.analyzer

1. 词法分析 将源代码分割为若干个记号（token）的处理。执行词法分析的程序称为词法分析器 . （lexical.analyzer）*。lex的工作就是根据词法规则自动生成词法分析器。 
2. 语法分析 即从记号构建分析树 （parse.tree）的处理。分析树也叫作语法树 . （syntax. tree）或抽象语法树 . （abstract.syntax.tree，AST）。执行语法分析的程序则称为解析器 （parser）。yacc就是能根据语法规则自动 生成解析器的程序。 
3. 语义分析 经过语法分析生成的分析树，并不包含数据类型等语义信息。因此在语义分析阶段，会检查程序中是否含有语法正确但是存在逻辑问题的错误。如将字符串赋给整形。 没有变量类型，则无需语义分析。
4. 生成代码

## lex文件
mycalc.l
```
%{
#include <stdio.h>
#include "mycalc.tab.h"

int
yywrap(void)
{
    return 1;
} 
%} 
%% 
"+"             return ADD;
"-"             return SUB;
"*"             return MUL;
"/"             return DIV; 16: "\n"            return CR;
([1-9][0-9]*)|0|([0-9]+\.[0-9]+) {
    double temp;
    sscanf(yytext, "%lf", &temp);
    yylval.double_value = temp;
    return DOUBLE_LITERAL;
} 
[ \t] ;
. {
    fprintf(stderr, "lexical error.\n");
    exit(1);
}
%%
```
%%，此行之前的部分叫作定义区块。在定义区块内，可以定 义初始状态或者为正则表达式命名。

%{ 和 %} 包裹的部分，是想让生成的词法分析器将 这部分代码原样输出。 yywrap() 的函数。如果没有这个函数的 话，就必须手动链接 lex 的库文件，在不同环境下编译时比较麻烦，因此最好 写上。

ADD、 SUB、 MUL、 DIV、 CR、 DOUBLE_LITERAL 等都是在 y.tab.h （yacc）或mycalc.tab.h(bison)中用 #define 定义的宏，其原始出处则定义于 mycalc.y 文件中。
在规则区块中遵循这样的书写方式：一个正则表达式的后面紧跟若干个空格， 后接 C 代码。如果输入的字符串匹配正则表达式，则执行后面的 C 代码。这里的 C 代码部分称为动作（action）。

“记号”，其实我们所说的记号是一个总称，包含三部 分含义，分别是：
1. 记号的种类 比如说计算器中的 123.456 这个记号，这个记号的种类是一个实数（ DOUBLE_ LITERAL）。 
2. 记号的原始字符(字面量） 一个记号会包含输入的原始字符，比如 123.456 这个记号的原始字符就 是 123.456。 
3. 记号的值 123.456 这个记号代表的是实数 123.456 的值的意思。

## yacc文件
 mycalc.y

```

%{
#include <stdio.h>
#include <stdlib.h>
#define YYDEBUG 1
%}
%union {
    int          int_value;
    double       double_value;
} 
%token <double_value>     DOUBLE_LITERAL
%token ADD SUB MUL DIV CR 
%type <double_value> expression term primary_expression
%% 
line_list
    : line 
    | line_list line  /* 或者是一个多行后接单行 */
    ;
line 
    : expression CR 
    {
        printf(">>%lf\n", $1);
    } 
    expression
    : term  /* 项 */
    | expression ADD term
    {
        $$ = $1 + $3;
    } 
    | expression SUB term 
    {
        $$ = $1 - $3;
    }
    ;
term
    : primary_expression /* 一元表达式 */
    | term MUL primary_expression 
    {
        $$ = $1 * $3;
    }
    | term DIV primary_expression
    {
        $$ = $1 / $3;
    }
    ;
primary_expression
    : DOUBLE_LITERAL /* 实数的字面常量 */
    ;
 %%
int yyerror(char const *str) 
{
    extern char *yytext;
    fprintf(stderr, "parser error near %s\n", yytext);
    return 0;
} 

int main(void) 
{
    extern int yyparse(void);
    extern FILE *yyin;

    yyin = stdin;
    if (yyparse()) {
        fprintf(stderr, "Error ! Error ! Error !\n");
        exit(1);
    }
}

```
#define YYDEBUG 1，这样将全局变量 yydebug 设置为一 个非零值后会开启 Debug 模式
第 6 ～ 9 行声明了记号以及非终结符的种类。
第 10 ～ 11 行是记号的声明。
规则区块。yacc 的规则区块，由语法规则以及 C 语言编写的相应动作两部分构成。 在 yacc 中，会使用类似 BNF（巴科斯范式，Backus.Normal.Form）的规范来 编写语法规则。 

yacc 所做的工作，可以想象成一个类似“俄罗斯方块” 的过程。 输入. 1 + 2 * 3，词法分析器分割出来的记号（最初是 1）会由右边进 入栈并堆积到左边。

mycalc 所有的计算都是采用 double 类型，所以记号 1 即是 DOUBLE_LITERAL。当记号进入的同时，会触发我们定义的规则：

```
primary_expression     
    : DOUBLE_LITERAL

```
然后记号会被换成 primary_expression
```
term 
| term MUL primary_expression  
{ 
$$ = $1 * $3; 
} 
```
大括号中的动作是使用 C 语言书写的，但与普通的 C 语言又略有不同，掺杂了一 些 $$、 $1、 $3 之类的表达式。 这些表达式中， $1、 $3 的意思是分别保存了 term 与 primary_expression. 的值。即 yacc 输出解析器的代码时，栈中相应位置的元素将会转换为一个能表述 元素特征的数组引用。由于这里的 $2 是乘法运算符（ *），并不存在记号值，因 此这里引用 $2 的话就会报错。 $1 与 $3 进行乘法运算，然后将其结果赋给 $$，这个结果值将保留在栈中。在 这个例子中，执行的计算为 2 * 3，所以其结果值 6 会保留在栈中（如图2-3）。

$1 与 $3 对应的应该是 term 和 primary_expression，而不是 2 与 3 这样的 DOUBLE_LITERAL 数值才对呀，为什么会作为 2.*.3 来计算呢？ 因为，yacc 会自动补全一个 { $$ = $1; } 的动作。

## 生成计算器程序
```
zhh@svr:~/mylang$ bison -dv mycalc.y # 生成mycalc.tab.c和mycalc.tab.h
or
zhh@svr:~/mylang$ bison --yacc -dv mycalc.y # 生成y.tab.h

zhh@svr:~/mylang$ flex mycalc.l
zhh@svr:~/mylang$ ls
lex.yy.c  mycalc.l  mycalc.output  mycalc.tab.c  mycalc.tab.h  mycalc.y
zhh@svr:~/mylang$ cc -o mycalc  mycalc.tab.c lex.yy.c
zhh@svr:~/mylang$ ./mycalc
1+2*3
>>7.000000
324i+2
lexical error.
zhh@svr:~/mylang$
```

# 自制词法分析器
操作本章的计算器时，会将换行作为分割符，把输入分割为一个个算式。跨复数行的输入是无法被解析为一个算式的，因此词法分析器中应当提供以下的 函数：
```
/* 将接下来要解析的行置入词法分析器中 */ 
 void set_line(char *line);
/* 从被置入的行中，分割记号并返回 * 在行尾会返回 END_OF_LINE_TOKEN 这种特殊的记号 */ 
void get_token(Token *token); 
```
token.h
```c
#ifndef TOKEN_H_INCLUDED
#define TOKEN_H_INCLUDED

typedef enum {
   BAD_TOKEN,
   NUMBER_TOKEN,
   ADD_OPERATOR_TOKEN,
   SUB_OPERATOR_TOKEN,
   MUL_OPERATOR_TOKEN,
   DIV_OPERATOR_TOKEN,
   END_OF_LINE_TOKEN
} TokenKind;

#define MAX_TOKEN_SIZE (100) 

typedef struct {
   TokenKind kind;
   double      value;
   char        str[MAX_TOKEN_SIZE];
} Token;

void set_line(char *line);
void get_token(Token *token);

#endif /* TOKEN_H_INCLUDED */
```

```c
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "token.h"

static char *st_line;
static int st_line_pos;

typedef enum {
    INITIAL_STATUS,
    IN_INT_PART_STATUS,
    DOT_STATUS,
    IN_FRAC_PART_STATUS
} LexerStatus;

void get_token(Token *token) 
{
    int out_pos = 0; 
    LexerStatus status = INITIAL_STATUS;
    char current_char;

    token->kind = BAD_TOKEN;
    while (st_line[st_line_pos] != '\0') {
        current_char = st_line[st_line_pos]; 
        if ((status == IN_INT_PART_STATUS || status == IN_FRAC_PART_STATUS) 
            && !isdigit(current_char) && current_char != '.') {
            token->kind = NUMBER_TOKEN;
            sscanf(token->str, "%lf", &token->value);
            return;
        }
        if (isspace(current_char)) {
            if (current_char == '\n') {
                token->kind = END_OF_LINE_TOKEN;
                return;
            }
            st_line_pos++;
            continue;
        }

        if (out_pos >= MAX_TOKEN_SIZE-1) {
            fprintf(stderr, "token too long.\n");
            exit(1);
        }
        token->str[out_pos] = st_line[st_line_pos];
        st_line_pos++;
        out_pos++;
        token->str[out_pos] = '\0';

        if (current_char == '+') {
            token->kind = ADD_OPERATOR_TOKEN;
            return;
        } else if (current_char == '-') {
            token->kind = SUB_OPERATOR_TOKEN;
            return;
        } else if (current_char == '*') {
            token->kind = MUL_OPERATOR_TOKEN;
            return;
        } else if (current_char == '/') {
            token->kind = DIV_OPERATOR_TOKEN;
            return;
        } else if (isdigit(current_char)) {
            if (status == INITIAL_STATUS) {
                status = IN_INT_PART_STATUS;
            } else if (status == DOT_STATUS) {
                status = IN_FRAC_PART_STATUS;
            }
        } else if (current_char == '.') {
            if (status == IN_INT_PART_STATUS) {
                status = DOT_STATUS;
            } else {
                fprintf(stderr, "syntax error.\n");
                exit(1);
            }
        } else {
            fprintf(stderr, "bad character(%c)\n", current_char);
            exit(1);
        }
    } 
} 

void
set_line(char *line) 
{
    st_line = line;
    st_line_pos = 0;
} 

/* 下面是测试驱动代码 */ 
void parse_line(char *buf) 
{ 
    Token token; 

    set_line(buf); 

    for (;;) { 
        get_token(&token); 
        if (token.kind == END_OF_LINE_TOKEN) { 
            break; 
        } else {
               printf("kind..%d, str..%s\n", token.kind, token.str);
        } 
    } 
} 

int 
main(int argc, char **argv) 
{ 
    char buf[1024]; 

    while (fgets(buf, 1024, stdin) != NULL) { 
        parse_line(buf); 
    } 
        return 0; 
}
```
get_token() 则负责将记号实际分割出来，即词法分析器的核心部分。 

数值部分要稍微复杂一些，因为数值由多个字符构成。鉴于我们采用的 是 while 语句逐字符扫描这种方法，当前扫描到的字符很有可能只是一个数值 的一部分，所以必须想个办法将符合数值特征的值暂存起来。为了暂存数值，我 们采用一个枚举类型 LexerStatus* 的全局变量 status（第 20 行）。 首先， status 的初始状态是 INITIAL_STATUS。当遇到 0 ～ 9 的数字时， 这些数字会被放入整数部分（此时状态为 IN_INT_PART_STATUS）中（第 64 行）。一旦遇到小数点 .， status 会由 IN_INT_PART_STATUS 切换为 DOT_ STATUS（第 70 行 ）， DOT_STATUS 再 遇 到 数 字 会 切 换 到 小 数 状 态（ IN_ FRAC_PART_STATUS，第 66 行）。在 IN_INT_PART_STATUS 或 IN_FRAC_ PART_STATUS 的状态下，如果再无数字或小数点出现，则结束，接受数值 并 return.

# 自制语法分析器
借鉴一下前人的智慧。因此我们 将使用一种叫递归下降分析的方法来编写语法分析器。 

些语法规则可以用图 2-5 这样的 语法图  . （syntax.graph 或 syntax.diagram） 来表示。

```c

#include <stdio.h>
#include <stdlib.h>
#include "token.h"

#define LINE_BUF_SIZE (1024)

static Token st_look_ahead_token;
static int st_look_ahead_token_exists;

static void
my_get_token(Token *token) 
{
    if (st_look_ahead_token_exists) {
        *token = st_look_ahead_token;
        st_look_ahead_token_exists = 0;
    } else {
        get_token(token);
    } 
} 

static void
unget_token(Token *token) 
{
    st_look_ahead_token = *token;
    st_look_ahead_token_exists = 1;
} 

double parse_expression(void);

static double
parse_primary_expression()
{
    Token token;

    my_get_token(&token);
    if (token.kind == NUMBER_TOKEN) {
        return token.value;
    }
    fprintf(stderr, "syntax error.\n");
    exit(1);
    return 0.0; /* make compiler happy */
}

static double
parse_term()
{
    double v1;

    double v2;
    Token token;

    v1 = parse_primary_expression();
    for (;;) {
        my_get_token(&token);
        if (token.kind != MUL_OPERATOR_TOKEN
            && token.kind != DIV_OPERATOR_TOKEN) {
            unget_token(&token);
            break;
        } 
        v2 = parse_primary_expression();
        if (token.kind == MUL_OPERATOR_TOKEN) {
            v1 *= v2;
        } else if (token.kind == DIV_OPERATOR_TOKEN) {
            v1 /= v2;
        }
    }
    return v1;
}

double
parse_expression()
{
    double v1;
    double v2;
    Token token;

    v1 = parse_term();
    for (;;) {
        my_get_token(&token);
        if (token.kind != ADD_OPERATOR_TOKEN 
            && token.kind != SUB_OPERATOR_TOKEN) {
            unget_token(&token);
            break;
        } 
        v2 = parse_term();
        if (token.kind == ADD_OPERATOR_TOKEN) {
            v1 += v2;
        } else if (token.kind == SUB_OPERATOR_TOKEN) {
            v1 -= v2;
        } else {
            unget_token(&token);
        }
    }
    return v1;
}

double
parse_line(void)
{
    double value;

    st_look_ahead_token_exists = 0;
    value = parse_expression();

    return value;
} 

int
main(int argc, char **argv) 
{
    char line[LINE_BUF_SIZE];
    double value;

    while (fgets(line, LINE_BUF_SIZE, stdin) != NULL) {
        set_line(line);
        value = parse_line();
        printf(">>%f\n", value);
    } 

    return 0;
}

```
递归下降解析法，会预先读入一个记号，一旦发现预读的记号是不需 要的，则通过 unget_token() 将记号“退回”。 

解析器会对记号进行预读，并按照语法图的流程读入所有记 号。这种类型的解析器叫作LL(1) 解析器。LL(1) 解析器所能解析的语法，叫作 LL(1) 语法。 

在实现递归下降分析时，如果仍然按这个规则在 parse_expression() 刚 开始就调用 parse_expression()，会造成死循环，一个记号也读不了。 BNF 这样的语法称为左递归，原封照搬左递归的语法规则，是无法实现递归 下降分析的。 所以 yacc 生成的解析器称为LALR(1) 解析器，这种解析器能解析的语法称 为LALR(1) 语法。LALR(1) 解析器是 LR 解析器的一种。 LL(1) 的第一个 L，代表记号从程序源代码的最左边开始读入。第二个 L 则 代表最左推导  （Leftmost.derivation），即读入的记号从左端开始置换为分析树。而 与此相对的 LR 解析器，从左端开始读入记号与 LL(1) 解析器一致，但是发生归 约时（参看 2.2.3 节图 2-3），记号从右边开始归约，这称为最右推导  （Rightmost. derivation），即 LR 解析器中 R 字母的意思。


 递归下降分析会按自上而下的顺序生成分析树，所以称作递归“下降”解析 器或递归“向下”解析器。而 LR 解析器则是按照自下而上的顺序，所以也称为 “自底向上”解析器。 此外，LL(1)、LALR(1) 等词汇中的 (1)，代表的是解析时所需前瞻符号 （lookahead.symbol），即记号的数量。 LALR(1) 开头的 LA 两个字母，是 Look.Ahead 的缩写，可以通过预读一个记 号判明语法规则中所包含的状态并生成语法分析表。LALR 也是由此得名的。 ，最近像 ANTLR、JavaCC 等一些采用 LL(k)，即预读任意个记号的 LL 解析器也开始普及起来。

