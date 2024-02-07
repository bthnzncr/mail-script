#ifndef __MS_H
#define __MS_H



typedef struct RecipientNode
{
    char *identifierName;
    char *address;
    char *stringName;
    int lineNum;
} RecipientNode;


typedef struct NormalNode
{
    char *value;
    int lineNum;
    int blockCounter;
} NormalNode;

typedef struct IdentNode

{   
    int blockCounter;
    char *name;
    int lineNum;
    char *value;
    int insideBlock;
} IdentNode;

typedef struct StringNode
{
    char *value;
    int lineNum;
} StringNode;

typedef struct SendNode
{   
    char *identifier;
    char* value;
    int lineNum;
    int blockCounter;
    int currentSend;
    RecipientNode **recipients;
    int currentRecipient;
    int insideSchedule;

} SendNode;

typedef struct ScheduleNode
{   
    int  day;
    int  month;
    int year; 
    char* time;
    SendNode** sends;
    int lineNum;
    int currentSend;
} ScheduleNode;





#endif