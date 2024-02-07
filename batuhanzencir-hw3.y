%{
#ifdef YYDEBUG
  yydebug = 1;
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "batuhanzencir-hw3.h"
void yyerror(const char *s) {
}
/*
BATUHAN ZENCIR
29080
SABANCI UNIVERSITY
*/
int blockCounter; // counter to keep track of the current block number in the program.

int insideSchedule = 0; // flag to indicate if the parser is currently inside a schedule block.

char* sender; // variable to hold the current sender address.
char** senderList; // list to store sender addresses.
int senderListSize = 100; 
int currentSenderList =0; // index to keep track of the current position in the senderList.

RecipientNode** recipientList; // list to store recipient nodes.
int currentRecipientList = 0; // index to keep track of the current position in the recipientList.
int recipientListSize = 100;

SendNode** sendList; // list to store send nodes which are part of a schedule block.
int currentSendList = 0; // index to keep track of the current position in the sendList.
int sendListSize =100;

SendNode** sendListFINAL; // list to store send nodes for final output.
int currentsendListFINAL = 0; // index to keep track of the current position in sendListFINAL.
int sendListFINALSize =100;

ScheduleNode** scheduleListFINAL; // list to store schedule nodes for final output.
int currentScheduleListFINAL = 0; // index to keep track of the current position in scheduleListFINAL.
int scheduleListFINALSize = 100;

char** errors; // list to store error messages.
int currentErrors = 0; // index to keep track of the current position in the errors list.
int errorsSize = 100;

IdentNode** localIdentifierList; // list to store local identifiers.
int currentLocalIdentifierList = 0; // index to keep track of the current position in the localIdentifierList.
int localIdentifierListSize = 100;

IdentNode** globalIdentifierList; // iist to store global identifiers.
int currentGlobalIdentifierList = 0; // index to keep track of the current position in the globalIdentifierList.
int globalIdentifierListSize = 100;

void clearLocalScope(); // clear local scope identifiers.
int isInLocalIdentifierList(IdentNode ident); //  check if an identifier is in the local identifier list.
void makeIdent(IdentNode ident, StringNode string); //  create an identifier node.
int isInGlobalIdentifierList(IdentNode ident); //  check if an identifier is in the global identifier list.
void makeSchedule(NormalNode date, NormalNode time, SendNode** list); //  create a schedule node and store it in scheduleListFinal.
void addToScheduleListFINAL(ScheduleNode* schedule); //  add a schedule node to the scheduleListFinal.
SendNode* makeSendwithIdent(IdentNode ident, RecipientNode** recipientList, int isScheduled); //  create a send node with an identifier.
SendNode* makeSendwithString(StringNode string, RecipientNode** recipientList, int isScheduled); // to create a send node with a string.
char* getIdentValue(char *identifierName); // get the value of an identifier.
RecipientNode* makeEmptyRecipient(NormalNode address); // create an empty recipient node.
RecipientNode* makeIdentRecipient(IdentNode ident, NormalNode address); //  create a recipient node with an identifier.
RecipientNode* makeStringRecipient(StringNode string, NormalNode address); //  create a recipient node with a string.
bool isEmailInRecipientList(RecipientNode* recipient, RecipientNode** recipientList); //  check if an email is in the recipient list.
void addToRecipientList(RecipientNode* recipient, RecipientNode** recipientList); //to add a recipient to the recipient list.
bool isValidDate(NormalNode date); //  validate date.
bool isValidTime(NormalNode time); //validate  time.
void addToSendList(SendNode* send, SendNode** sendList); //add a send node to the sendList.
void makeSender(NormalNode address); // function to set the sender address.
void addToSendListFINAL(SendNode* send); // add a send node to the sendListFINAL.
RecipientNode** createRecipientList(RecipientNode* recipient); //  create a recipient list.
SendNode** createSendList(SendNode* send); // create a send list.
void sortScheduleListFINAL(ScheduleNode** scheduleList); // sorts the scheduleListFINAL.
char* convertDate(int day, int month, int year); //  convert a date to a string.
void differentiateSends(ScheduleNode** schedules, SendNode** allSends); //  mark sends within schedules.

%}


%union{
    SendNode *sendNodePtr;
    ScheduleNode *scheduleNodePtr;
    RecipientNode* recipientNodePtr;
    IdentNode identNode;
    RecipientNode **recipientList;
    NormalNode normalNode;
    StringNode stringNode;
    SendNode **sendList;
    int blockCounter;
    
}

%token  tENDMAIL tENDSCHEDULE tSEND tTO tFROM tSET tCOMMA tCOLON tLPR tRPR tLBR tRBR tAT tSCHEDULE
%token <normalNode> tTIME
%token <normalNode> tDATE
%token <normalNode> tADDRESS
%token <identNode> tIDENT
%token <stringNode> tSTRING
%token <blockCounter> tMAIL

%start program

%type <sendList> sendStatements
%type <sendNodePtr> sendStatement
%type <recipientNodePtr> recipient
%type <recipientList> recipientList
%type <scheduleNodePtr> scheduleStatement

%%

program : statements
;

statements : 
            | setStatement statements
            | mailBlock statements
;

mailBlock : tMAIL tFROM tADDRESS tCOLON statementList tENDMAIL{ makeSender($3); 
                                                                clearLocalScope();}
;

statementList : 
                | setStatement statementList
                | sendStatement statementList
                | scheduleStatement statementList
;

sendStatements : 
    sendStatements sendStatement { 
        addToSendList($2, $1);  
        $$ = $1; 
    }
    | sendStatement { 
        $$ = createSendList($1);
    }
;


sendStatement : 
    tSEND tLBR tIDENT tRBR tTO tLBR recipientList tRBR { 
        $$ = makeSendwithIdent($3, $7, insideSchedule);  
        if (!insideSchedule) { addToSendListFINAL($$); }
    }
    | tSEND tLBR tSTRING tRBR tTO tLBR recipientList tRBR { 
        $$ = makeSendwithString($3, $7, insideSchedule);  
        if (!insideSchedule) { addToSendListFINAL($$); }
    }
;

recipientList
    : recipientList tCOMMA recipient {
        
        addToRecipientList($3, $1);
        $$ = $1;
    }
    | recipient {
        
        $$ = createRecipientList($1);
    }
;


recipient : tLPR tADDRESS tRPR{ $$ = makeEmptyRecipient($2);}
            | tLPR tSTRING tCOMMA tADDRESS tRPR { $$ = makeStringRecipient($2, $4);}
            | tLPR tIDENT tCOMMA tADDRESS tRPR { $$ = makeIdentRecipient($2, $4);}
;

scheduleStatement : tSCHEDULE tAT tLBR tDATE tCOMMA tTIME tRBR tCOLON { insideSchedule = 1; } sendStatements tENDSCHEDULE { 
    makeSchedule($4, $6, $10); 
    insideSchedule = 0;  
}
;

setStatement : tSET tIDENT tLPR tSTRING tRPR { makeIdent($2, $4);}
;


%%


int main()
{
	globalIdentifierList = (IdentNode**)malloc((sizeof(IdentNode*) * globalIdentifierListSize));
	localIdentifierList = (IdentNode**)malloc((sizeof(IdentNode*) * localIdentifierListSize));
	senderList = (char**)malloc((sizeof(char*) * senderListSize));
	errors = (char**)malloc(sizeof(char*) * errorsSize);
	sendListFINAL = (SendNode**)malloc((sizeof(SendNode*) * sendListFINALSize));
	scheduleListFINAL = (ScheduleNode**)malloc((sizeof(ScheduleNode*) * scheduleListFINALSize));
	if (yyparse())
	{
		printf("ERROR\n");
		return 1;
	}
	else
	{

		if (currentErrors != 0) {
			int i = 0;
			for (; i<  currentErrors; i++) {
				printf("%s", errors[i]);
			}
		}
		else {
			differentiateSends(scheduleListFINAL, sendListFINAL);


			int i = 0;
			for (; i < currentsendListFINAL; i++) {
				if (sendListFINAL[i]->insideSchedule == 2) {
					int k = 0;
					for (; k < sendListFINAL[i]->currentSend; k++) {
						char* recipientDisplay;

						if (sendListFINAL[i]->recipients[k]->stringName) {

							char* originalDisplay = sendListFINAL[i]->recipients[k]->stringName;
							recipientDisplay = strndup(originalDisplay + 1, strlen(originalDisplay) - 2);
						}
						else {

							recipientDisplay = sendListFINAL[i]->recipients[k]->address;
						}

						char* emailDisplay = sendListFINAL[i]->value;
						char* senderAddress = senderList[sendListFINAL[i]->blockCounter - 1];

						printf("E-mail sent from %s to %s: %s\n", senderAddress, recipientDisplay, emailDisplay);
						if (sendListFINAL[i]->recipients[k]->stringName) {
							//free(recipientDisplay);
						}
					}
				}
			}


			if (currentScheduleListFINAL >= 0) {
				sortScheduleListFINAL(scheduleListFINAL);

				int y = 0;

				for (; y < currentScheduleListFINAL; y++) {
					ScheduleNode* schedule = scheduleListFINAL[y];
					char* formattedDate = convertDate(schedule->day, schedule->month, schedule->year);

					int j = 0;

					for (; j < schedule->currentSend; j++) {
						SendNode* send = schedule->sends[j];
						int k = 0;
						for (; k < send->currentSend; k++) {
							char* recipientDisplay;

							if (send->recipients[k]->stringName) {

								char* originalDisplay = send->recipients[k]->stringName;
								recipientDisplay = strndup(originalDisplay + 1, strlen(originalDisplay) - 2);
							}
							else {

								recipientDisplay = send->recipients[k]->address;
							}

							char* emailDisplay = send->value;
							char* senderAddress = senderList[send->blockCounter - 1];

							printf("E-mail scheduled to be sent from %s on %s, %s to %s: %s\n", senderAddress, formattedDate, schedule->time, recipientDisplay, emailDisplay);
							if (send->recipients[k]->stringName) {
								//free(recipientDisplay);
							}
						}
					}

					//free(formattedDate);
				}
			}
		}



	}

    //this code below is not required for this homework and not completed. will be updated later





    /*
    // clear allocated memory from heap for globalIdentifierList.
    int i = 0;
	for (; i < currentGlobalIdentifierList; i++) {
		if (globalIdentifierList[i] != NULL) {

			free(globalIdentifierList[i]->name);
			free(globalIdentifierList[i]->value);

			free(globalIdentifierList[i]);
			globalIdentifierList[i] = NULL;
		}
	}
	currentGlobalIdentifierList = 0;
    free(globalIdentifierList);
    globalIdentifierList=NULL;


    // clear allocated memory from heap for sendListFINAL.
    int k = 0;
	for (; k < currentErrors; k++) {
		if (errors[k]!= NULL) {

			free(errors[k]);
			errors[k] =NULL;
		}
	}
    free(errors);
    errors =NULL; 
    currentErrors =0;
    
int a = 0;
    for (; a < currentsendListFINAL; a++) {
        if (sendListFINAL[a] !=NULL) {
            free(sendListFINAL[a]->value); 
            free(sendListFINAL[a]->identifier); 

            int j= 0;
            for (; j < sendListFINAL[a]->currentSend; j++) {
                free(sendListFINAL[a]->recipients[j]->address); 
                 free(sendListFINAL[a]->recipients[j]->stringName); 
                free(sendListFINAL[a]->recipients[j]->identifierName); 
                free(sendListFINAL[a]->recipients[j]); 
            }
             free(sendListFINAL[a]->recipients); 

            free(sendListFINAL[a]); 
            sendListFINAL[a]=NULL;
        }
    }
    
    free(sendListFINAL); 
    
    currentsendListFINAL =0;
    sendListFINAL = NULL;

	// clear allocated memory from heap for sendListFINAL.

    int b = 0;
    for (; b < currentScheduleListFINAL; b++) {
        if (scheduleListFINAL[b] != NULL) {

            free(scheduleListFINAL[b]->time); 
            free(scheduleListFINAL[b]); 
            scheduleListFINAL[b] = NULL;
        }
    }
    
    free(scheduleListFINAL); 
    scheduleListFINAL =NULL;
    currentScheduleListFINAL = 0;

    // clear allocated memory from heap for senderList.
    int w = 0;
        for (; w < blockCounter; w++) {
            if (senderList[w]!= NULL) {

                free(senderList[w]);
                senderList[w] =NULL;
            }
        }
        free(senderList);
        senderList =NULL; 
        */
    return 0;
}


void makeIdent(IdentNode ident, StringNode string) {


	IdentNode* newIdent = (IdentNode*)malloc(sizeof(IdentNode));
	newIdent->blockCounter = ident.blockCounter;
	newIdent->value = strdup(string.value);;
	newIdent->lineNum = ident.lineNum;
	newIdent->insideBlock = ident.insideBlock;
	newIdent->name = strdup(ident.name);

	if ((ident.insideBlock == 1 && isInLocalIdentifierList(ident) == -1)) {
		if(localIdentifierListSize > currentLocalIdentifierList){
			localIdentifierList[currentLocalIdentifierList] = newIdent;
		currentLocalIdentifierList++;
		}
		else{
			localIdentifierListSize = localIdentifierListSize + localIdentifierListSize;
			localIdentifierList = realloc(localIdentifierList, localIdentifierListSize);
			localIdentifierList[currentLocalIdentifierList] = newIdent;
			currentLocalIdentifierList++;

		}

	}
	else if ((ident.insideBlock == 1 && isInLocalIdentifierList(ident) != -1)) {
		localIdentifierList[isInLocalIdentifierList(ident)] = newIdent;

	}
	else if ((ident.insideBlock == 0 && isInGlobalIdentifierList(ident) == -1)) {

		if(globalIdentifierListSize > currentGlobalIdentifierList){
			globalIdentifierList[currentGlobalIdentifierList] = newIdent;
		currentGlobalIdentifierList++;
		}
		else{
			globalIdentifierListSize = globalIdentifierListSize + globalIdentifierListSize;
			globalIdentifierList = realloc(globalIdentifierList, globalIdentifierListSize);
			globalIdentifierList[currentGlobalIdentifierList] = newIdent;
			currentGlobalIdentifierList++;

		}

	}
	else if ((ident.insideBlock == 0 && isInGlobalIdentifierList(ident) != -1)) {

		globalIdentifierList[isInGlobalIdentifierList(ident)] = newIdent;

	}
}

int isInLocalIdentifierList(IdentNode ident) {
	int i = 0;
	for (; i < currentLocalIdentifierList; i++) {
		if ((strcmp(localIdentifierList[i]->name, ident.name) == 0)) {

			return i;
		}
	}

	return -1;
}
int isInGlobalIdentifierList(IdentNode ident) {
	int i = 0;
	for (; i < currentGlobalIdentifierList; i++) {
		if (strcmp(globalIdentifierList[i]->name, ident.name) == 0) {

			return i;
		}
	}
	return -1;

}
char* getIdentValue(char* identifierName) {

	int i = 0;
	for (; i < currentLocalIdentifierList; i++) {
		if (strcmp(localIdentifierList[i]->name, identifierName) == 0) {
			return localIdentifierList[i]->value;
		}
	}

	int k = 0;

	for (; k < currentGlobalIdentifierList; k++) {
		if (strcmp(globalIdentifierList[k]->name, identifierName) == 0) {
			return globalIdentifierList[k]->value;
		}
	}

	return NULL;
}

void clearLocalScope() {
	int i = 0;
	for (; i < currentLocalIdentifierList; i++) {
		if (localIdentifierList[i] != NULL) {

			free(localIdentifierList[i]->name);
			free(localIdentifierList[i]->value);

			free(localIdentifierList[i]);
			localIdentifierList[i] = NULL;
		}
	}
	currentLocalIdentifierList = 0;
}


RecipientNode* makeEmptyRecipient(NormalNode address) {
	RecipientNode* newRecipient = (RecipientNode*)malloc(sizeof(RecipientNode));
	newRecipient->address = strdup(address.value);
	newRecipient->lineNum = address.lineNum;
	newRecipient->stringName = NULL;
	newRecipient->identifierName = NULL;

	return newRecipient;
}

RecipientNode* makeIdentRecipient(IdentNode ident, NormalNode address) {

	RecipientNode* newRecipient = (RecipientNode*)malloc(sizeof(RecipientNode));
	if (!newRecipient) {

		return NULL;
	}

	newRecipient->address = strdup(address.value);
	newRecipient->lineNum = address.lineNum;
	newRecipient->identifierName = strdup(ident.name);
	newRecipient->stringName = NULL;


	int localIndex = isInLocalIdentifierList(ident);
	int globalIndex = isInGlobalIdentifierList(ident);

	if (!(localIndex == -1 && globalIndex == -1)) {
		newRecipient->stringName = strdup((localIndex != -1) ? localIdentifierList[localIndex]->value : globalIdentifierList[globalIndex]->value);

	}
	return newRecipient;
}

RecipientNode* makeStringRecipient(StringNode string, NormalNode address) {


	RecipientNode* newRecipient = (RecipientNode*)malloc(sizeof(RecipientNode));
	newRecipient->address = strdup(address.value);
	newRecipient->lineNum = address.lineNum;
	newRecipient->stringName = strdup(string.value);
	newRecipient->identifierName = NULL;
	return newRecipient;
}

RecipientNode** createRecipientList(RecipientNode* recipient) {

	currentRecipientList = 0;
	recipientList = (RecipientNode**)malloc((sizeof(RecipientNode*) * recipientListSize));
	recipientList[currentRecipientList] = recipient;
	currentRecipientList++;
	return recipientList;
}

void addToRecipientList(RecipientNode* recipient, RecipientNode** recipientList) {

		
	
	if (!isEmailInRecipientList(recipient, recipientList)) {
		if(currentRecipientList < recipientListSize){
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
			return;
		}
		else{
			recipientListSize = recipientListSize + recipientListSize;
			recipientList = realloc(recipientList, recipientListSize );
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
			return;
		}
	}
	else if (currentErrors != 0) {
		if(currentRecipientList < recipientListSize){
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
			return;
		}
		else{
			recipientListSize = recipientListSize + recipientListSize;
			recipientList = realloc(recipientList, recipientListSize );
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
			return;
		}
			
	}
	IdentNode tempIdent;

		tempIdent.name = recipient->identifierName;
		if (tempIdent.name != NULL) {
			int identLocalIndex = isInLocalIdentifierList(tempIdent);
			int identGlobalIndex = isInGlobalIdentifierList(tempIdent);

			if (identLocalIndex == -1 && identGlobalIndex == -1) {
				if(currentRecipientList < recipientListSize){
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
		}
		else{
			recipientListSize = recipientListSize + recipientListSize;
			recipientList = realloc(recipientList, recipientListSize );
			recipientList[currentRecipientList] = recipient;
			currentRecipientList++;
		}
			}
			}
	
}
void makeSender(NormalNode address) {
	sender = malloc(strlen(address.value) + 1);
	strcpy(sender, address.value);
	if(currentSenderList < senderListSize){
		senderList[currentSenderList] = sender;

		currentSenderList++;
	}
	else{
		senderListSize = senderListSize+senderListSize;
		senderList = realloc(senderList, senderListSize);
		senderList[currentSenderList] = sender;
		currentSenderList++;
	}
}

SendNode** createSendList(SendNode* send) {
	currentSendList =0;
	if (send == NULL) {

		return NULL;
	}
	SendNode** sendList = (SendNode**)malloc(sizeof(SendNode*) * sendListSize);
	if (sendList == NULL) {

		return NULL;
	}
	sendList[0] = send;
	currentSendList = 1;

	return sendList;
}

void addToSendList(SendNode* send, SendNode** sendList) {
	if (send == NULL || sendList == NULL) {

		return;
	}
    if(currentSendList > sendListSize){
		sendListSize = sendListSize+sendListSize;
		sendList = realloc(sendList, sendListSize);
		sendList[currentSendList] = send;
		currentSendList++;

	}
	else{
	sendList[currentSendList] = send;
	currentSendList++;
	}
	
}


SendNode* makeSendwithString(StringNode string, RecipientNode** recipientList, int isScheduled) {

	SendNode* newSend = (SendNode*)malloc(sizeof(SendNode));
	if (!newSend) {

		return NULL;
	}

	newSend->identifier = NULL;
	newSend->value = strdup(string.value);
	newSend->lineNum = string.lineNum;

	newSend->blockCounter = blockCounter;
	newSend->currentSend = currentRecipientList;
	newSend->recipients = recipientList;
	newSend->insideSchedule = isScheduled;
	int k = 0;
	for (; k < newSend->currentSend; k++) {

		IdentNode tempIdent;

		tempIdent.name = recipientList[k]->identifierName;

		if (tempIdent.name != NULL) {

			int identLocalIndex = isInLocalIdentifierList(tempIdent);
			int identGlobalIndex = isInGlobalIdentifierList(tempIdent);

			if (identLocalIndex == -1 && identGlobalIndex == -1) {
				char* error = (char*)malloc(256 * sizeof(char));
				if (error) {

					if(currentErrors >  errorsSize){
						errorsSize = errorsSize + errorsSize;
						errors = realloc(errors, errorsSize);
						snprintf(error, 255, "ERROR at line %d: %s is undefined\n", recipientList[k]->lineNum, recipientList[k]->identifierName);
						
						errors[currentErrors] = error;
						currentErrors++;
					}
					else{
						snprintf(error, 255, "ERROR at line %d: %s is undefined\n", recipientList[k]->lineNum, recipientList[k]->identifierName);

						errors[currentErrors] = error;
						currentErrors++;
					}
					
				}
			}
		}
	}
	return newSend;
}

SendNode* makeSendwithIdent(IdentNode ident, RecipientNode** recipientList, int isScheduled) {

	SendNode* newSend = (SendNode*)malloc(sizeof(SendNode));
	if (!newSend) {

		return NULL;
	}

	newSend->identifier = strdup(ident.name);
	newSend->value = NULL;
	newSend->lineNum = ident.lineNum;

	newSend->blockCounter = blockCounter;
	newSend->currentSend = currentRecipientList;
	newSend->recipients = recipientList;
	newSend->insideSchedule = isScheduled;

	int localIndex = isInLocalIdentifierList(ident);
	int globalIndex = isInGlobalIdentifierList(ident);
	if (localIndex == -1 && globalIndex == -1) {

		char* error = (char*)malloc(255 * sizeof(char));
		if (error) {
			if(currentErrors >  errorsSize){
						errorsSize = errorsSize+ errorsSize;
						errors = realloc(errors, errorsSize);
						snprintf(error, 255, "ERROR at line %d: %s is undefined\n", ident.lineNum, ident.name);

						errors[currentErrors] = error;
						currentErrors++;
					}
			else{
						snprintf(error, 255, "ERROR at line %d: %s is undefined\n", ident.lineNum, ident.name);

						errors[currentErrors] = error;
						currentErrors++;
			}
		}
	}
	else {

		newSend->value = strdup((localIndex != -1) ? localIdentifierList[localIndex]->value : globalIdentifierList[globalIndex]->value);
	}

	int k = 0;
	for (; k < newSend->currentSend; k++) {

		IdentNode tempIdent;

		tempIdent.name = recipientList[k]->identifierName;
		if (tempIdent.name != NULL) {
			int identLocalIndex = isInLocalIdentifierList(tempIdent);
			int identGlobalIndex = isInGlobalIdentifierList(tempIdent);

			if (identLocalIndex == -1 && identGlobalIndex == -1) {
				char* error = (char*)malloc(256 * sizeof(char));
				if (error) {

					if(currentErrors >  errorsSize){
						errorsSize = errorsSize+ errorsSize;
						errors = realloc(errors, errorsSize);
						snprintf(error, 255, "ERROR at line %d: %s is undefined\n", recipientList[k]->lineNum, recipientList[k]->identifierName);

						errors[currentErrors] = error;
						currentErrors++;
					}
					else{
					snprintf(error, 255, "ERROR at line %d: %s is undefined\n", recipientList[k]->lineNum, recipientList[k]->identifierName);

						errors[currentErrors] = error;
						currentErrors++;
					}


				}
			}
		}
	}

	return newSend;
}


void addToSendListFINAL(SendNode* send) {

	if (send->identifier != NULL) {

		char* value = getIdentValue(send->identifier);


		if (value != NULL) {
			send->value = strdup(value);
		}
	}


	int i = 0;
	for (; i < send->currentSend; i++) {
		if (send->recipients[i]->identifierName != NULL) {
			char* identValue = getIdentValue(send->recipients[i]->identifierName);
			if (identValue != NULL) {

				send->recipients[i]->stringName = strdup(identValue);
			}
		}
	}
	if(currentsendListFINAL > sendListFINALSize){
		sendListFINALSize = sendListFINALSize+sendListFINALSize;
		sendListFINAL = realloc (sendListFINAL,sendListFINALSize);
		sendListFINAL[currentsendListFINAL] = send;
		currentsendListFINAL++;
	}
	else{
	sendListFINAL[currentsendListFINAL] = send;
	currentsendListFINAL++;

	}
	
}



void addToScheduleListFINAL(ScheduleNode* schedule) {

	if(currentScheduleListFINAL > scheduleListFINALSize){

		scheduleListFINALSize =  scheduleListFINALSize+scheduleListFINALSize;
		scheduleListFINAL = realloc(scheduleListFINAL, scheduleListFINALSize);
		scheduleListFINAL[currentScheduleListFINAL] = schedule;
		currentScheduleListFINAL++;
	}
	else{
		scheduleListFINAL[currentScheduleListFINAL] = schedule;
		currentScheduleListFINAL++;

	}
	
}
bool isValidDate(NormalNode date) {
	int day, month, year;
	char separator1, separator2;

	if (sscanf(date.value, "%d%c%d%c%d", &day, &separator1, &month, &separator2, &year) != 5) {
		return false;
	}


	if (month < 1 || month > 12) {
		return false;
	}


	int daysInMonth[] = { 31, (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

	if (day < 1 || day > daysInMonth[month - 1]) {
		return false;
	}

	return true;
}

bool isValidTime(NormalNode time) {
	int hour, minute;


	if (sscanf(time.value, "%d:%d", &hour, &minute) != 2) {
		return false;
	}


	if (hour < 0 || hour > 23) {
		return false;
	}

	if (minute < 0 || minute > 59) {
		return false;
	}

	return true;
}

void makeSchedule(NormalNode date, NormalNode time, SendNode** sendList) {


	int day, month, year;
	char separator1, separator2;

	if (sscanf(date.value, "%d%c%d%c%d", &day, &separator1, &month, &separator2, &year) != 5) {
		return;
	}

	ScheduleNode* newSchedule = (ScheduleNode*)malloc(sizeof(ScheduleNode));
	if (!newSchedule) {
		return;
	}

	newSchedule->day = day;
	newSchedule->month = month;
	newSchedule->year = year;
	newSchedule->time = strdup(time.value);
	newSchedule->sends = sendList;
	newSchedule->lineNum = date.lineNum;


	newSchedule->currentSend = 0;
	int i = 0;
	for (; sendList[i] != NULL; i++) {
		newSchedule->currentSend++;
	}

	if (!isValidDate(date)) {
		char* error = (char*)malloc(255 * sizeof(char));
		if (error) {
			
			if(currentErrors > errorsSize){
						errorsSize = errorsSize+ errorsSize;
						errors = realloc(errors, errorsSize);
						snprintf(error, 255, "ERROR at line %d: date object is not correct (%s)\n", date.lineNum, date.value);
						errors[currentErrors] = error;
						currentErrors++;
					}
					else{
						snprintf(error, 255, "ERROR at line %d: date object is not correct (%s)\n", date.lineNum, date.value);
						errors[currentErrors] = error;
						currentErrors++;
					}
		}
	}
	if (!isValidTime(time)) {
		char* error = (char*)malloc(255 * sizeof(char));
		if (error) {
			if(currentErrors >  errorsSize){
						errorsSize = errorsSize+ errorsSize;
						errors = realloc(errors, errorsSize);
						snprintf(error, 255, "ERROR at line %d: time object is not correct (%s)\n", time.lineNum, time.value);

						errors[currentErrors] = error;
						currentErrors++;
					}
					else{
						snprintf(error, 255, "ERROR at line %d: time object is not correct (%s)\n", time.lineNum, time.value);

						errors[currentErrors] = error;
						currentErrors++;
					}
		}
	}

	addToScheduleListFINAL(newSchedule);
}




bool isEmailInRecipientList( RecipientNode* recipient, RecipientNode** recipientList) {
	char*email = recipient->address;
	int i = 0;
	for (; i < currentRecipientList; i++) {
		if (recipientList[i] != NULL && strcmp(recipientList[i]->address, email) == 0) {
			return true;
		}
	}
	return false;
}



char* convertDate(int day, int month, int year) {
	const char* months[] = { "January", "February", "March", "April", "May", "June",
							"July", "August", "September", "October", "November", "December" };
	char* newDate = (char*)malloc(30 * sizeof(char));
	if (newDate) {
		snprintf(newDate, 30, "%s %d, %d", months[month - 1], day, year);
	}
	return newDate;
}

void swapScheduleNodes(ScheduleNode** a, ScheduleNode** b) {
	ScheduleNode* temp =*a;
	*a = *b;
	*b = temp;
}

int compareScheduleNodes(ScheduleNode* a, ScheduleNode* b) {

	if (a->year != b->year) 
	return a->year - b->year;
	if (a->month != b->month) 
	return a->month - b->month;
	if (a->day != b->day) 
	return a->day - b->day;
	int timeComparison = strcmp(a->time, b->time);
	if (timeComparison != 0) 
	return timeComparison;
	return a->lineNum -b->lineNum;
}


void sortScheduleListFINAL(ScheduleNode** scheduleList) {
	int i, j;
	i = 0;
	for (; i < currentScheduleListFINAL - 1; i++) {
		j = 0;
		for (; j < currentScheduleListFINAL - i - 1; j++) {
			if (compareScheduleNodes(scheduleList[j], scheduleList[j + 1]) > 0) {
				swapScheduleNodes(&scheduleList[j], &scheduleList[j + 1]);
			}
		}
	}
}

void differentiateSends(ScheduleNode** schedules, SendNode** allSends) {
	
	int i = 0;
	for (; i < currentScheduleListFINAL; i++) {
		ScheduleNode* schedule = schedules[i];
		int j = 0;
		for (; j < schedule->currentSend; j++) {
			schedule->sends[j]->insideSchedule = 1;

		}
	}


	int k = 0;
	for (; k < currentsendListFINAL; k++) {
		if (allSends[k]->insideSchedule == 0) {
			allSends[k]->insideSchedule = 2;


		}
	}
}
