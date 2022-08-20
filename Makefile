#####################################################################
## file        : Makefile for build current dir .c                 ##
## author      : zhouhh 					   ##
## date-time   : 2020-03-17                                        ##
#####################################################################

## target exec file name
TARGET     := mycalc

# YACC	= bison -yacc -dv
BISON	= bison -dv
FLEX	= flex

CC      = gcc
CPP     = g++
# -rm 表示出现问题也继续执行
RM      = -rm 

## debug flag
DBG_ENABLE   = 1

## source file path
SRC_PATH   := .

## get all source files,wildcard 表示展开成所有.c文件的集合
SRCS         += $(wildcard $(SRC_PATH)/*.c)
YACC_SRCS	+= $(wildcard $(SRC_PATH)/*.y)
LEX_SRCS	+= $(wildcard $(SRC_PATH)/*.l)

## all .o based on all .c
OBJS        := $(SRCS:.c=.o)

## need libs, add at here
LIBS := pthread

## used headers  file path
INCLUDE_PATH := .

## used include librarys file path
LIBRARY_PATH := /lib

## debug for debug info, when use gdb to debug
ifeq (1, ${DBG_ENABLE}) 
	CFLAGS += -D_DEBUG -O0 -g -DDEBUG=1
endif

## get all include path
CFLAGS  += $(foreach dir, $(INCLUDE_PATH), -I$(dir))

## get all library path
LDFLAGS += $(foreach lib, $(LIBRARY_PATH), -L$(lib))

## get all librarys
LDFLAGS += $(foreach lib, $(LIBS), -l$(lib))

# .PHONY 伪目标，不管是否存在clean这个文件，目标都执行, 不是文件而是标签.总是被执行
.PHONY : clean lex yacc build all

all: yacc lex build

yacc:	
	@echo "yacc src:"$(YACC_SRCS)
	$(BISON) $(YACC_SRCS)

lex:	$(LEX_SRCS)	
	@echo $(LEX_SRCS)
	$(FLEX) $(LEX_SRCS) 

build:
	$(CC) -c $(CFLAGS) $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)
	$(RM) $(OBJS)

clean:
	$(RM) $(OBJS) $(TARGET)
