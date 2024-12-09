%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define MAX_STR_LEN	100
#include "modula.tab.h"
int process_token(const char *text, const char *TokenType,
		  const char *TokenVal, const int TokenID); 
char *strnncpy(char *dst, const char *src, const int n);

int comment_start = 0;
int double_quote_start = 0;
int single_quote_start = 0;
%}

 /* stany analizatora leksykalnego (INITIAL jest zdefiniowany) */
%option yylineno
%x ST_COMMENT
%x ST_DOUBLE_QUOTE
%x ST_SINGLE_QUOTE

 /* pomocnicze */

%%
 /* B. wykrywanie słów kluczowych zdefiniowanych w pliku źródłowym modula.y dla programu bison jako nazwy z przedrostkiem KW_ w dyrektywie %token */
AND return process_token(yytext, "KW_AND", "", KW_AND);
BEGIN return process_token(yytext, "KW_BEGIN", "", KW_BEGIN);
CONST return process_token(yytext, "KW_CONST", "", KW_CONST);
DIV return process_token(yytext, "KW_DIV", "", KW_DIV);
DO return process_token(yytext, "KW_DO", "", KW_DO);
ELSE return process_token(yytext, "KW_ELSE", "", KW_ELSE);
ELSIF return process_token(yytext, "KW_ELSIF", "", KW_ELSIF);
END return process_token(yytext, "KW_END", "", KW_END);
FOR return process_token(yytext, "KW_FOR", "", KW_FOR);
FROM return process_token(yytext, "KW_FROM", "", KW_FROM);
IF return process_token(yytext, "KW_IF", "", KW_IF);
IMPORT return process_token(yytext, "KW_IMPORT", "", KW_IMPORT);
IN return process_token(yytext, "KW_IN", "", KW_IN);
MOD return process_token(yytext, "KW_MOD", "", KW_MOD);
MODULE return process_token(yytext, "KW_MODULE", "", KW_MODULE);
NOT return process_token(yytext, "KW_NOT", "", KW_NOT);
OR return process_token(yytext, "KW_OR", "", KW_OR);
THEN return process_token(yytext, "KW_THEN", "", KW_THEN);
TYPE return process_token(yytext, "KW_TYPE", "", KW_TYPE);
TO return process_token(yytext, "KW_TO", "", KW_TO);
VAR return process_token(yytext, "KW_VAR", "", KW_VAR);
WHILE return process_token(yytext, "KW_WHILE", "", KW_WHILE);
REPEAT return process_token(yytext, "KW_REPEAT", "", KW_REPEAT);
UNTIL return process_token(yytext, "KW_UNTIL", "", KW_UNTIL);
LOOP return process_token(yytext, "KW_LOOP", "", KW_LOOP);
CASE return process_token(yytext, "KW_CASE", "", KW_CASE);
OF return process_token(yytext, "KW_OF", "", KW_OF);
ARRAY return process_token(yytext, "KW_ARRAY", "", KW_ARRAY);
RECORD return process_token(yytext, "KW_RECORD", "", KW_RECORD);
DOWNTO return process_token(yytext, "KW_DOWNTO", "", KW_DOWNTO);
PROCEDURE return process_token(yytext, "KW_PROCEDURE", "", KW_PROCEDURE);

 /* C. usuwanie białych znaków */
[[:space:]]+ ;

 /* D. wykrywanie operatorów wieloznakowych (<=, :=,…) występujących w programach testowych */
".." return process_token(yytext, "RANGE", "", RANGE);
":=" return process_token(yytext, "ASSIGN", "", ASSIGN);
"<=" return process_token(yytext, "LE", "", LE);
">=" return process_token(yytext, "GE", "", GE);

 /* E. wykrywanie identyfikatorów */
[[:alpha:]][[:alpha:][:digit:]]* return process_token(yytext, "IDENT", yytext, IDENT);

 /* F. wykrywanie liczb całkowitych bez znaku */
[0-9]+ return process_token(yytext, "INTEGER_CONST", yytext, INTEGER_CONST);

 /* G. wykrywanie liczb rzeczywistych bez znaku */
 [0-9]+(\.[0-9]+)?(E[+-]?[0-9]+)? return process_token(yytext, "FLOAT_CONST", yytext, REAL_CONST);

 /* H. wykrywanie stałych tekstowych (napisów) w cudzysłowach bez użycia mechanizmu warunków początkowych */
  \"[^"\n]*\" return process_token(yytext, "STRING_CONST", yytext, STRING_CONST);

 /* I. wykrywanie stałych znakowych w apostrofach bez użycia mechanizmu warunków początkowych */
  '.' return process_token(yytext, "CHAR_CONST", yytext, CHAR_CONST);

 /* J. wykrywanie symboli końcowych jednoznakowych: operatorów, interpunkcji */
 [,=:;().*+-.|<[\]] return process_token(yytext, yytext, "", yytext[0]);;

  /* K. wykrywanie napisów w cudzysłowach z użyciem warunków początkowych */
<INITIAL>\" BEGIN(ST_DOUBLE_QUOTE);
<ST_DOUBLE_QUOTE>[^"\n]*\" {BEGIN(INITIAL); return process_token(yytext, "STRING_CONST", yytext, STRING_CONST);}
 
 /* L. wykrywanie stałych znakowych w apostrofach z użyciem warunków początkowych */
<INITIAL>' BEGIN(ST_SINGLE_QUOTE);
<ST_SINGLE_QUOTE>.' {BEGIN(INITIAL); return process_token(yytext, "CHAR_CONST", yytext, CHAR_CONST);}
 
 /* M. usuwanie komentarzy wielowierszowych z użyciem warunków początkowych */
<INITIAL>"(*" { BEGIN(ST_COMMENT); comment_start = yylineno; }
<ST_COMMENT>.|\n
<ST_COMMENT>"*)" BEGIN(INITIAL);

 /* N. znajdowanie znaków zamknięcia komentarza przy braku jego rozpoczęcia z użyciem warunków początkowych */
<INITIAL>"*)" printf("Comment closed in line %d when none opened\n", yylineno);

 /* O. wykrywanie niezamkniętego komentarza ze wskazaniem wiersza jego rozpoczęcia z użyciem warunków początkowych */
<ST_COMMENT><<EOF>> { printf("Comment opened in line %d not closed\n", comment_start); yyterminate(); }


%%

int yywrap() {
  return 1; /* obligatory!!! */
}

/* Name:	strnncpy
 * Purpose:	copies given number of characters of a string appending 
 *		character with code 0 at the end.
 * Parameters:	dst		- (o) target string;
 *		src		- (i) source string;
 *		n		- (i) max character number to be copied.
 * Returns:	dst.
 * Remarks:	strncpy does not append character code 0 after copied string.
 *		Target string must have room for n+1 characters.
 */
char *
strnncpy(char *dst, const char *src, const int n)
{
  if (n > 0) {
    strncpy(dst, src, n);
  }
  dst[n] = '\0';
  return dst;
}/*strnncpy*/


/* Name:	process_token
 * Purpose:     Print information about detected token and pass it up
 *              with its value if it is present.
 * Parameters:  text            - (i) matched text;
 *              TokenType       - (i) textual representation of token type;
 *              TokenVal        - (i) token value if present
 *              TokenID         - (i) token identifier declared with %token
 *                                      in modula.y file.
 * Returns:	Token type identifier (TokenID).
 * Uwagi:       Information about the detected token is printed in 3 columns.
 *              The first one contains the matched text,
 *		the second - token type, the third - token value if present.
 */
int process_token(const char *text, const char *TokenType,
		  const char *TokenVal, const int TokenID)
{
  int l;
  printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
  switch (TokenID) {

  case INTEGER_CONST:
    yylval.i = atoi(text); break;

  case REAL_CONST:
    yylval.d = atof(text); break;

  case IDENT:
    strncpy(yylval.s, text, MAX_STR_LEN); break;

  case STRING_CONST:
    l = strlen(text);
    strnncpy(yylval.s, TokenVal+1, l - 2 <= MAX_STR_LEN ? l - 1 : MAX_STR_LEN);
    break;

  }
  return(TokenID);
}
