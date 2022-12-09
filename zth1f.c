/* Forth cross-compiler for the ZTH1 computer

   By S. Morel, Zthorus Labs 

   Date          Action
   ----          ------
   2022-12-05    Added constant declarations
   2021-12-03    Calling words containing do-loops from inside a do-loop ok
   2021-12-02    Corrected bug in compilation of "=" word
   2021-12-01    Added sprite-control words
   2021-11-24    First release on GitHub
   2021-11-01    Created
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NB_BASE_WORDS 59
#define DATA_START_ADDR 6270

void locase(char *sOut,char *sIn);
int getAtom(FILE *f,char *a,int *l);
int isInteger(char *s);
int validWord(char *a,char **baseWord);
void zCode(char **objCode,char *mem,char *opCode,int *pcPtr,int *itPtr,int its);
void zValue(char **objCode,int x,int pc);
int writeFile(char *name,char **obj,char *mem,int b);
int readFile(char *name,char **obj,char *mem,int b);
int readLine(FILE *f,char *s);
int hex2dec(char *s);
int zHexData(char **objData,char *ram,char *latom,int *dataAddr);
int zStringData(FILE *f,char **objData,char *mem,int *dataAddr);

enum comp_state {GLOBAL,INCLUDE_FILES,DEFINE_GVAR,COMMENT,DEFINE_WORD1,DEFINE_WORD2,DEFINE_LVAR,DEFINE_DATA1,DEFINE_DATA2,END_FILE,DEFINE_GCST1,DEFINE_GCST2,DEFINE_LCST1,DEFINE_LCST2};

enum errc {FILE_NOT_FOUND,INVALID_VARIABLE_NAME,INVALID_CONSTANT_NAME,INVALID_WORD_NAME,INTEGER_OUT_OF_RANGE,INVALID_STRUCT,INVALID_DATA_ADDRESS,INVALID_NUMBER,STRING_TOO_LONG,OVERFLOW,UNEXPECTED_END};

int main(int argc, char **argv)
{
  FILE *fSource;         /* source file currently read */
  char **fileList;       /* list of source files */
  int nbFiles;           /* number of source files to read */
  int fIdx;              /* index of file currently read */
  int fileRead;          /* =1 if file being read */

  char atom[80];         /* currently parsed atom */
  char latom[80];        /* atom in lower case characters */
  enum comp_state cmpState;  /* compiler state */
  int cmpSavedState;     /* previous compiler state */
  char word[40];         /* currently declared word */

  int lineNb;            /* current line-number of source code */ 
  enum errc errCodeList[50];  /* list of errors encountered */
  char **errArgList;     /* list of faulty arguments */
  int errLine[50];       /* line-numbers of errors */
  char errMsg[160];      /* displayed error message */
  int errIdx;            /* index of error list */
  int maxErr;            /* =1 if maximum number of errors reached */

  char **fndLabelTable;  /* table of found labels (Forth words or
                            variables or constants) */
  char **fndLabelScopeTable; /* table of scopes of labels */
  int *fndLabelAddr;     /* addresses of found labels */
  char **varTable;       /* table of declared variables */
  char **varScopeTable;  /* table of scopes of declared variables */
  char **cstTable;       /* table of declared constants */
  char **cstScopeTable;  /* table of scopes of declared constants */
  int cstValue[300];     /* values of constants */
  int varAddr[300];      /* addresses of variables */
  int curVarAddr;        /* current variable address */
  char **wordTable;      /* table of declared Forth words */
  int wordAddr[80];      /* addresses of words (targets for calls) */
  int flIdx;             /* found-label index */
  int wIdx;              /* declared-word index */
  int vIdx;              /* variables index */
  int cIdx;              /* constants index */

  int ietState[20];      /* if-else-then-structure state (stack) */
  int ietElseSrc[20];    /* source address of jump after "if" (stack) */
  int ietThenSrc[20];    /* source address of jump after else (stack) */
  int ietStkPtr;         /* if-else-then-structure stack pointer */
  int srcJump;           /* source address of jump */
  int buTgt[20];         /* begin-until target address of jump (stack)*/
  int buStkPtr;          /* begin-until stack pointer */
  int dlTgt[80];         /* do-loop target address of jump (stack) */
  int dlStkPtr;          /* do-loop stack pointer */
  int dlStkPtr0;         /* level 0 of dlStkPtr relative to a word */ 
  int dlMaxLevel;        /* maximum nesting level reached for do-loops */
  char startI[4];        /* do-loop start value (and current idx) variable */
  char stopI[4];         /* do-loop stop value variable */ 
 
  int dataAddr;          /* address of RAM-stored data */
  int dataAddrSaved;     /* back-up of address of data */

  char **baseWord;       /* base forth dictionary */
  char **baseCode;       /* ZTH1 code of words in base dictionary */
  int its[NB_BASE_WORDS];/* starting IT value for ZTH1 op-code sequence */
  char hexVal[5];        /* value in hexadecimal */
  char opCode[32];       /* sequence of ZTH1 op-codes for a Forth word */
  int pc;                /* simulated ZTH1 program-counter register */
  int it;                /* simulated ZTH1 instruction toggle flag */
  int pc2;               /* auxiliary PC */
  int it2;               /* auxiliary IT */
  char **objCode;        /* object code (list of 16-bit hexadecimal values) */
  char **objData;        /* object data (to be split into RAM_H and RAM_L) */
  char rom[8192];        /* 16-bit words in ROM used */
  char ram[8192];        /* 16-bit words in RAM used */

  int i,j,k,l,m,n; 

  char dum[40];

  if (argc != 2)
  {
    printf("Syntax: zth1f <source file>\n");
    exit(0);
  }

  fileList=malloc(20*sizeof(char *));
  if (fileList==NULL) exit(0);
  for (i=0;i<20;i++)
  {
    fileList[i]=malloc(40*sizeof(char));
    if (fileList[i]==NULL)
    {
      printf("No memory left for fileList[%d]\n",i);
      exit(0);
    }
  }
  errArgList=malloc(50*sizeof(char *));
  if (errArgList==NULL) exit(0);
  for (i=0;i<50;i++)
  {
    errArgList[i]=malloc(40*sizeof(char));
    if (errArgList[i]==NULL)
    {
      printf("No memory left for errArgList[%d]\n",i);
      exit(0);
    }
  }
  fndLabelTable=malloc(1000*sizeof(char *));
  if (fndLabelTable==NULL) exit(0);
  for (i=0;i<1000;i++)
  {
    fndLabelTable[i]=malloc(40*sizeof(char));
    if (fndLabelTable[i]==NULL)
    {
      printf("No memory left for fndLabelTable[%d]\n",i);
      exit(0);
    }
  }
  fndLabelScopeTable=malloc(1000*sizeof(char *));
  if (fndLabelScopeTable==NULL) exit(0);
  for (i=0;i<1000;i++)
  {
    fndLabelScopeTable[i]=malloc(40*sizeof(char));
    if (fndLabelScopeTable[i]==NULL)
    {
      printf("No memory left for fndLabelScopeTable[%d]\n",i);
      exit(0);
    }
  }
  fndLabelAddr=malloc(1000*sizeof(int));
  varTable=malloc(300*sizeof(char *));
  if (varTable==NULL) exit(0);
  for (i=0;i<300;i++)
  {
    varTable[i]=malloc(40*sizeof(char));
    if (varTable[i]==NULL)
    {
      printf("No memory left for varTable[%d]\n",i);
      exit(0);
    }
  }
  varScopeTable=malloc(300*sizeof(char *));
  if (varScopeTable==NULL) exit(0);
  for (i=0;i<300;i++)
  {
    varScopeTable[i]=malloc(40*sizeof(char));
    if (varScopeTable[i]==NULL)
    {
      printf("No memory left for varScopeTable[%d]\n",i);
      exit(0);
    }
  }
  cstTable=malloc(300*sizeof(char *));
  if (cstTable==NULL) exit(0);
  for (i=0;i<300;i++)
  {
    cstTable[i]=malloc(40*sizeof(char));
    if (cstTable[i]==NULL)
    {
      printf("No memory left for cstTable[%d]\n",i);
      exit(0);
    }
  }
  cstScopeTable=malloc(300*sizeof(char *));
  if (cstScopeTable==NULL) exit(0);
  for (i=0;i<300;i++)
  {
    cstScopeTable[i]=malloc(40*sizeof(char));
    if (cstScopeTable[i]==NULL)
    {
      printf("No memory left for cstScopeTable[%d]\n",i);
      exit(0);
    }
  }
  wordTable=malloc(80*sizeof(char *));
  if (wordTable==NULL) exit(0);
  for (i=0;i<80;i++)
  {
    wordTable[i]=malloc(40*sizeof(char));
    if (wordTable[i]==NULL)
    {
      printf("No memory left for wordTable[%d]\n",i);
      exit(0);
    }
  }
  baseWord=malloc(NB_BASE_WORDS*sizeof(char *));
  if (baseWord==NULL) exit(0);
  baseCode=malloc(NB_BASE_WORDS*sizeof(char *));
  if (baseCode==NULL) exit(0);
  for (i=0;i<NB_BASE_WORDS;i++)
  {
    baseWord[i]=malloc(10*sizeof(char));
    if (baseWord[i]==NULL)
    {
      printf("No memory left for baseWord[%d]\n",i);
      exit(0);
    }
    baseCode[i]=malloc(50*sizeof(char));
    if (baseCode[i]==NULL)
    {
      printf("No memory left for baseCode[%d]\n",i);
      exit(0);
    }
  }
  objCode=(char **)malloc(8192*sizeof(char *));
  objData=(char **)malloc(8192*sizeof(char *));
  for (i=0;i<8192;i++)
  {
    rom[i]='0';
    ram[i]='0';
    objCode[i]=(char *)malloc(5*sizeof(char));
    objData[i]=(char *)malloc(5*sizeof(char));
  }
  /* printf("baseWord setting\n"); */

  strcpy(baseWord[0],"!");
  strcpy(baseCode[0],"100A0F0F"); its[0]=2; 
  strcpy(baseWord[1],"@");
  strcpy(baseCode[1],"07"); its[1]=2;
  strcpy(baseWord[2],"+");
  strcpy(baseCode[2],"17100F"); its[2]=2;
  strcpy(baseWord[3],"-");
  strcpy(baseCode[3],"18100F"); its[3]=2;
  strcpy(baseWord[4],"1+");
  strcpy(baseCode[4],"15"); its[4]=2;
  strcpy(baseWord[5],"1-");
  strcpy(baseCode[5],"16"); its[5]=2;
  strcpy(baseWord[6],"and");
  strcpy(baseCode[6],"19100F"); its[6]=2;
  strcpy(baseWord[7],"or");
  strcpy(baseCode[7],"1A100F"); its[7]=2;
  strcpy(baseWord[8],"xor");
  strcpy(baseCode[8],"1B100F"); its[8]=2;
  strcpy(baseWord[9],"not");
  strcpy(baseCode[9],"1C"); its[9]=2;
  strcpy(baseWord[10],"neg");
  strcpy(baseCode[10],"1D"); its[10]=2;

  strcpy(baseWord[11],"2/");
  strcpy(baseCode[11],"1E21"); its[11]=2;
  strcpy(baseWord[12],"2*");
  strcpy(baseCode[12],"1E23"); its[12]=2;
  strcpy(baseWord[13],"dup");
  strcpy(baseCode[13],"0E"); its[13]=2;
  strcpy(baseWord[14],"drop");
  strcpy(baseCode[14],"0F"); its[14]=2;
  strcpy(baseWord[15],"over");
  strcpy(baseCode[15],"100E11"); its[15]=2;
  strcpy(baseWord[16],"swap");
  strcpy(baseCode[16],"10"); its[16]=2;
  strcpy(baseWord[17],"rolldn3");
  strcpy(baseCode[17],"13"); its[17]=2;
  strcpy(baseWord[18],"rollup3");
  strcpy(baseCode[18],"11"); its[18]=2;
  strcpy(baseWord[19],"rolldn4");
  strcpy(baseCode[19],"14"); its[19]=2;
  strcpy(baseWord[20],"rollup4");
  strcpy(baseCode[20],"12"); its[20]=2;
  strcpy(baseWord[21],"<");
  strcpy(baseCode[21],"180F0F0300020023"); its[21]=1;
  strcpy(baseWord[22],">");
  strcpy(baseCode[22],"10180F0F0300020023"); its[22]=0;
  strcpy(baseWord[23],"=");
  strcpy(baseCode[23],"250F0F0300020103000200270C"); its[23]=1;

  /* structuring words */

  strcpy(baseWord[24],"if");
  strcpy(baseCode[24],"03000201250F0F000300020028"); its[24]=0;
  strcpy(baseWord[25],"if=");
  strcpy(baseCode[25],"250300020028"); its[25]=1;
  strcpy(baseWord[26],"if!=");
  strcpy(baseCode[26],"250300020027"); its[26]=1;
  strcpy(baseWord[27],"if<");
  strcpy(baseCode[27],"25030002002A"); its[27]=1;
  strcpy(baseWord[28],"if>");
  strcpy(baseCode[28],"10251000030002002A"); its[28]=0;
  strcpy(baseWord[29],"if>=");
  strcpy(baseCode[29],"250300020029"); its[29]=1;
  strcpy(baseWord[30],"if<=");
  strcpy(baseCode[30],"102510000300020029"); its[30]=0;
  strcpy(baseWord[31],"else");
  strcpy(baseCode[31],"030002002600"); its[31]=0;
  strcpy(baseWord[32],"then");
  strcpy(baseCode[32],""); its[32]=0;
  strcpy(baseWord[33],"begin");
  strcpy(baseCode[33],""); its[33]=0;
  strcpy(baseWord[34],"until");
  strcpy(baseCode[34],"03000201250F0F000300020028"); its[34]=0;
  strcpy(baseWord[35],"until=");
  strcpy(baseCode[35],"250300020028"); its[35]=1;
  strcpy(baseWord[36],"until!=");
  strcpy(baseCode[36],"250300020027"); its[36]=1;
  strcpy(baseWord[37],"until<");
  strcpy(baseCode[37],"25030002002A"); its[37]=1;
  strcpy(baseWord[38],"until>");
  strcpy(baseCode[38],"10251000030002002A"); its[38]=0;
  strcpy(baseWord[39],"until>=");
  strcpy(baseCode[39],"250300020029"); its[39]=1;
  strcpy(baseWord[40],"until<=");
  strcpy(baseCode[40],"102510000300020029"); its[40]=0;
  strcpy(baseWord[41],"do");
  strcpy(baseCode[41],"03000200100A0F0F03000200100A0F0F"); its[41]=0;
  strcpy(baseWord[42],"loop");
  strcpy(baseCode[42],"030002000E07150A100F0300020007250F0F030002002A"); its[42]=0;
  strcpy(baseWord[43],"i");
  strcpy(baseCode[43],"0300020007"); its[43]=0;
 
  /* words calling OS routines */
  strcpy(baseWord[44],".");
  strcpy(baseCode[44],"030102972B"); its[44]=0;
  strcpy(baseWord[45],".\"");
  strcpy(baseCode[45],"030002000301023B2B"); its[45]=0;
  strcpy(baseWord[46],"u*");
  strcpy(baseCode[46],"030002062B"); its[46]=0;
  strcpy(baseWord[47],"*");
  strcpy(baseCode[47],"0300021F2B"); its[47]=0;
  strcpy(baseWord[48],"/");
  strcpy(baseCode[48],"030002722B"); its[48]=0;
  strcpy(baseWord[49],"/mod");
  strcpy(baseCode[49],"030002762B"); its[49]=0;
  strcpy(baseWord[50],"at");
  strcpy(baseCode[50],"0301028F2B"); its[50]=0;
  strcpy(baseWord[51],"cr");
  strcpy(baseCode[51],"0301021F2B"); its[51]=0;
  strcpy(baseWord[52],"emit");
  strcpy(baseCode[52],"0300027A2B"); its[52]=0;
  strcpy(baseWord[53],"cls");
  strcpy(baseCode[53],"0301028A2B"); its[53]=0;
  strcpy(baseWord[54],"joystick");
  strcpy(baseCode[54],"030102ED2B"); its[54]=0;
  strcpy(baseWord[55],"defsprite");
  strcpy(baseCode[55],"030102F92B"); its[55]=0;
  strcpy(baseWord[56],"putsprite");
  strcpy(baseCode[56],"0302020F2B"); its[56]=0;
  strcpy(baseWord[57],"colorsprite");
  strcpy(baseCode[57],"0302021B2B"); its[57]=0;
  strcpy(baseWord[58],"hidesprite");
  strcpy(baseCode[58],"0302022E2B"); its[58]=0;

  strcpy(fileList[0],argv[1]);
  nbFiles=1;
  fIdx=0;
  errIdx=0;
  curVarAddr=DATA_START_ADDR;
  vIdx=0; cIdx=0; wIdx=0; flIdx=0;
  maxErr=0;
  pc=600;
  it=0;
  ietStkPtr=0; buStkPtr=0; dlStkPtr=0;
  for (i=0;i<20;i++) ietState[i]=0;
  dlMaxLevel=0;

  /* read OS files of ZTH1 computer */
  if (readFile("os_rom.mif",objCode,rom,2)==-1) exit(0);
  if (readFile("os_ram_h.mif",objData,ram,0)==-1) exit(0);
  if (readFile("os_ram_l.mif",objData,ram,1)==-1) exit(0);
  

  printf("Start pass 1...\n");

  /* pass 1: converting Forth code into ZTH1 code */

  while (fIdx!=nbFiles)
  {
    fSource=fopen(fileList[fIdx],"r");
    if (fSource==NULL)
    {
      errCodeList[errIdx]=FILE_NOT_FOUND;
      strcpy(errArgList[errIdx],fileList[fIdx]);
      errIdx++;
      /* abort pass 1 */
      fIdx=nbFiles;
    }
    else
    {
      cmpState=GLOBAL;
      lineNb=1;
      fileRead=1;

      while (fileRead==1)
      {
        if (!getAtom(fSource,atom,&lineNb))
        {
          fileRead=0;
          cmpSavedState=cmpState;
          cmpState=END_FILE;
        }
        else
        {
          locase(latom,atom);
          /* printf("%s %s\n",atom,latom);*/
        }

        switch(cmpState)
        {
          case GLOBAL:
        
          if (strcmp(atom,"#")==0)
          {
            cmpState=INCLUDE_FILES;
          }
          if (strcmp(atom,":")==0)
          {
            cmpState=DEFINE_WORD1;
          }
          if (strcmp(atom,"(")==0)
          {
            cmpSavedState=GLOBAL;
            cmpState=COMMENT;
          }
          if ((strcmp(latom,"var")==0) || (strcmp(latom,"variable")==0))
          {
            cmpState=DEFINE_GVAR;
          }
          if ((strcmp(latom,"cst")==0) || (strcmp(latom,"constant")==0))
          {
            /* printf("Declaring global constant\n"); */
            cmpState=DEFINE_GCST1;
          }
          if (strcmp(latom,"data")==0)
          {
            cmpState=DEFINE_DATA1;
          }
          break;
 
          case INCLUDE_FILES:
        
          /* check if end of file list */
          if (strcmp(atom,";")==0)
          {
            cmpState=GLOBAL;
          }
          else
          {
            strcpy(fileList[nbFiles],atom);
            nbFiles++;
          }
          break;
        
          case COMMENT:
        
          if (strcmp(atom,")")==0) cmpState=cmpSavedState;
          break;
 
          case DEFINE_GVAR:
        
          cmpState=GLOBAL;
          if (validWord(latom,baseWord))
          {
            strcpy(varTable[vIdx],latom);
            strcpy(varScopeTable[vIdx],"global");
            varAddr[vIdx]=curVarAddr;
            curVarAddr++;
            vIdx++; 
          }
          else
          {
            errCodeList[errIdx]=INVALID_VARIABLE_NAME;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
          }
          break; 
         
          case DEFINE_GCST1:

          cmpState=DEFINE_GCST2;
          if (validWord(latom,baseWord))
          {
            /* printf("Constant name is %s\n",latom); */
            strcpy(cstTable[cIdx],latom);
            strcpy(cstScopeTable[cIdx],"global");
          }
          else
          {
            errCodeList[errIdx]=INVALID_CONSTANT_NAME;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
          }
          break;

          case DEFINE_GCST2:

          cmpState=GLOBAL;
          if (isInteger(atom)==1)
          {
            n=atoi(atom);
            if ((n<-32768) || (n>65535))
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              if (n<0) n+=65536;
              /* printf("Value of %s is %d\n",cstTable[cIdx],n); */
              cstValue[cIdx]=n;
              cIdx++;
            }
          }
          else if (atom[0]=='$')
          {
            n=hex2dec(atom+1);
            if (n>65535)
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              cstValue[cIdx]=n;
              cIdx++;
            }
          }
          break;

          case DEFINE_WORD1:
        
          if (validWord(latom,baseWord))
          {
            strcpy(wordTable[wIdx],latom);
            strcpy(word,latom);
            /* words always start at it=0 */
            if (it==1) zCode(objCode,rom,"00",&pc,&it,2);
            wordAddr[wIdx]=pc;
            wIdx++;
            /* the following allows to call a word using a do-loop
               from within another do-loop without mixing up the indices
               (at the expense of more memory used for the variables) */
            dlStkPtr0=dlMaxLevel;
            dlStkPtr=dlStkPtr0;
            cmpState=DEFINE_WORD2;
          }
          else
          {
            errCodeList[errIdx]=INVALID_WORD_NAME;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
          }
          break; 
         
          case DEFINE_WORD2:
        
          if (strcmp(atom,";")==0)
          {
            cmpState=GLOBAL;
            /* end of word => RET */
            zCode(objCode,rom,"30",&pc,&it,2);
            /* check completion of structures */
            if ((ietStkPtr!=0) || (buStkPtr!=0) || (dlStkPtr!=dlStkPtr0))
            {
              errCodeList[errIdx]=INVALID_STRUCT;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
          }
          else if (strcmp(atom,"(")==0)
          {
            cmpSavedState=DEFINE_WORD2;
            cmpState=COMMENT;
          }
          else if ((strcmp(latom,"var")==0) || (strcmp(latom,"variable")==0))
          {
             cmpState=DEFINE_LVAR;
          }
          else if ((strcmp(latom,"cst")==0) || (strcmp(latom,"constant")==0))
          {
             cmpState=DEFINE_LCST1;
          }
          /* if atom = number to push into stack */
          else if (isInteger(atom)==1)
          {
            n=atoi(atom);
            if ((n<-32768) || (n>65535))
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              if (n<0) n+=65536;
              strcpy(opCode,"03000200");
              zCode(objCode,rom,opCode,&pc,&it,0);
              zValue(objCode,n,pc-2);
            }
          }
          else if (atom[0]=='$')
          {
            n=hex2dec(atom+1);
            if (n>65535)
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              strcpy(opCode,"03000200");
              zCode(objCode,rom,opCode,&pc,&it,0);
              zValue(objCode,n,pc-2);
            }
          }

          /* check if word is in base dictionary */
          else
          {
            for (i=0;i<NB_BASE_WORDS;i++)
            {
              if (strcmp(latom,baseWord[i])==0) break;
            }
            if (i<NB_BASE_WORDS)
            {
              /* printf ("\nbase word %s found\n",baseWord[i]);*/
              zCode(objCode,rom,baseCode[i],&pc,&it,its[i]);
              if (i==23)
              {
                /* "=" statement */
                zValue(objCode,pc,pc-3);
              }
              if ((i>=24) && (i<=30))
              {
                /* "if" statement */
                ietStkPtr++;
                ietState[ietStkPtr]=1;
                ietElseSrc[ietStkPtr]=pc-2;
              }
              if (i==31)
              {
                /* "else" statement */
                if (ietState[ietStkPtr]!=1)
                {
                  errCodeList[errIdx]=INVALID_STRUCT;
                  strcpy(errArgList[errIdx],atom);
                  errLine[errIdx]=lineNb;
                  errIdx++;
                }
                else
                {
                  /* complete jump address of previous "if" */
                  zValue(objCode,pc,ietElseSrc[ietStkPtr]);
                  ietThenSrc[ietStkPtr]=pc-3;
                  ietState[ietStkPtr]=2;
                }
              }
              if (i==32)
              {
                /* "then" statement */
                if (ietState[ietStkPtr]==0)
                {
                  errCodeList[errIdx]=INVALID_STRUCT;
                  strcpy(errArgList[errIdx],atom);
                  errLine[errIdx]=lineNb;
                  errIdx++;
                }
                else
                {
                  /* distinguish "if then" and "if else then" */
                  if (ietState[ietStkPtr]==1) srcJump=ietElseSrc[ietStkPtr];
                  else srcJump=ietThenSrc[ietStkPtr];
                  zValue(objCode,pc,srcJump);
                  ietState[ietStkPtr]=0;
                  ietStkPtr--;
                }
              }
              if (i==33)
              {
                /* "begin" statement */
                buStkPtr++;
                buTgt[buStkPtr]=pc;
              }
              if ((i>=34) && (i<=40))
              {
                /* "until" statement */
                zValue(objCode,buTgt[buStkPtr],pc-2);
                buStkPtr--;
              }
              if (i==41)
              {
                /* "do" statement */
                dlStkPtr++;
                dlTgt[dlStkPtr]=pc;
                /* "do-loop" use "invisible" variables "n" and "0n"
                   n is the level of the loop
                   "n" : starting index of loop (also current index)
                   "0n": maximum index of loop (loop ends before)
                */ 
                sprintf(startI,"%d",dlStkPtr);
                sprintf(stopI,"0%d",dlStkPtr);
                if (dlStkPtr>dlMaxLevel)
                {
                  /* define loop variables if needed */
                  strcpy(varTable[vIdx],startI);
                  strcpy(varScopeTable[vIdx],"global");
                  varAddr[vIdx]=curVarAddr;
                  curVarAddr++;
                  vIdx++; 
                  strcpy(varTable[vIdx],stopI);
                  strcpy(varScopeTable[vIdx],"global");
                  varAddr[vIdx]=curVarAddr;
                  curVarAddr++;
                  vIdx++; 
                  dlMaxLevel=dlStkPtr;
                }
                strcpy(fndLabelTable[flIdx],startI);
                fndLabelAddr[flIdx]=pc-8;
                flIdx++;
                strcpy(fndLabelTable[flIdx],stopI);
                fndLabelAddr[flIdx]=pc-4;
                flIdx++;
              }
              if (i==42)
              {
                /* "loop" statement */
                if (dlStkPtr==0)
                {
                  errCodeList[errIdx]=INVALID_STRUCT;
                  strcpy(errArgList[errIdx],atom);
                  errLine[errIdx]=lineNb;
                  errIdx++;
                }
                else
                {
                  zValue(objCode,dlTgt[dlStkPtr],pc-2);
                  sprintf(startI,"%d",dlStkPtr);
                  sprintf(stopI,"0%d",dlStkPtr);
                  strcpy(fndLabelTable[flIdx],startI);
                  fndLabelAddr[flIdx]=pc-11;
                  flIdx++;
                  strcpy(fndLabelTable[flIdx],stopI);
                  fndLabelAddr[flIdx]=pc-6;
                  flIdx++;
                  dlStkPtr--;
                }
              }
              if (i==43)
              {
                /* "i" statement */
                if (dlStkPtr==0)
                {
                  errCodeList[errIdx]=INVALID_STRUCT;
                  strcpy(errArgList[errIdx],atom);
                  errLine[errIdx]=lineNb;
                  errIdx++;
                }
                else
                {
                  sprintf(startI,"%d",dlStkPtr);
                  strcpy(fndLabelTable[flIdx],startI);
                  fndLabelAddr[flIdx]=pc-2;
                  flIdx++;
                }
              }
              if (i==45)
              {
                /* print character string (.") */
                /* address of string = address of upcoming data */
                zValue(objCode,curVarAddr,pc-4);
                if (zStringData(fSource,objData,ram,&curVarAddr)==0)
                {
                  errCodeList[errIdx]=STRING_TOO_LONG;
                  errLine[errIdx]=lineNb;
                  errIdx++;
                }
              }
            }
            else
            {
              /* check if atom is a declared constant */
             
              for (i=0;i<cIdx;i++) 
              {
                /* printf("%d : %s %s\n",i,cstTable[i],cstScopeTable[i]); */
                if ((strcmp(latom,cstTable[i])==0) &&
                    ((strcmp(cstScopeTable[i],"global")==0) ||
                     (strcmp(cstScopeTable[i],word)==0))) break;
              }
              if (i!=cIdx) strcpy(opCode,"03000200");
              else
              {
                /* user-defined word or variable */
                /* check if variable or word already defined
                   this may avoid NOP insertion (that may later
                   be replaced by a CAL or not)
                   Anyway, substitution to numerical value will
                   be done in the 2nd pass
                */
                for (i=0;i<vIdx;i++)
                {
                  if ((strcmp(latom,varTable[i])==0) &&
                      ((strcmp(varScopeTable[i],"global")==0) ||
                       (strcmp(varScopeTable[i],word)==0))) break;
                }
                if (i!=vIdx) strcpy(opCode,"03000200");
                else
                {
                  for (i=0;i<wIdx;i++)
                  {
                    if (strcmp(latom,wordTable[i])==0) break;
                  }
                  if (i!=wIdx) strcpy(opCode,"030002002B");
                  else strcpy(opCode,"0200030000");
                }
              }
              zCode(objCode,rom,opCode,&pc,&it,0);
              strcpy(fndLabelTable[flIdx],latom);
              strcpy(fndLabelScopeTable[flIdx],word);
              fndLabelAddr[flIdx]=pc-2;
              flIdx++;
            }
          }
          break; 

          case DEFINE_LVAR:

          cmpState=DEFINE_WORD2;
          if (validWord(latom,baseWord))
          {
            strcpy(varTable[vIdx],latom);
            strcpy(varScopeTable[vIdx],word);
            varAddr[vIdx]=curVarAddr;
            curVarAddr++;
            vIdx++; 
          }
          else
          {
            errCodeList[errIdx]=INVALID_VARIABLE_NAME;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
          }
          break;

          case DEFINE_LCST1:

          cmpState=DEFINE_LCST2; 
          if (validWord(latom,baseWord))
          {
            strcpy(cstTable[cIdx],latom);
            strcpy(cstScopeTable[cIdx],word);
          }
          else
          {
            errCodeList[errIdx]=INVALID_CONSTANT_NAME;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
          }
          break;

          case DEFINE_LCST2:

          cmpState=DEFINE_WORD2;
          if (isInteger(atom)==1)
          {
            n=atoi(atom);
            if ((n<-32768) || (n>65535))
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              if (n<0) n+=65536;
              cstValue[cIdx]=n;
              cIdx++;
            }
          }
          else if (atom[0]=='$')
          {
            n=hex2dec(atom+1);
            if (n>65535)
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              cstValue[cIdx]=n;
              cIdx++;
            }
          }
          break;

          case DEFINE_DATA1:
      
          if (isInteger(atom)==1)
          {
            dataAddr=atoi(atom);
          }
          else if (atom[0]=='$')
          {
            dataAddr=hex2dec(atom+1);
          }
          else
          {
            if (validWord(latom,baseWord))
            {
              strcpy(varTable[vIdx],latom);
              strcpy(varScopeTable[vIdx],"global");
              varAddr[vIdx]=curVarAddr;
              dataAddr=curVarAddr;
              vIdx++; 
            }
            else
            {
              errCodeList[errIdx]=INVALID_VARIABLE_NAME;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
          }
          /* printf("data address: %d\n",dataAddr);*/
          if ((dataAddr<DATA_START_ADDR) || (dataAddr>8192))
          {
            errCodeList[errIdx]=INVALID_DATA_ADDRESS;
            strcpy(errArgList[errIdx],atom);
            errLine[errIdx]=lineNb;
            errIdx++;
            dataAddr=DATA_START_ADDR;
          }
          cmpState=DEFINE_DATA2;
          break;

          case DEFINE_DATA2:

          dataAddrSaved=dataAddr; 
          if (isInteger(atom)==1)
          {
            /* printf("data is decimal integer\n");*/
            n=atoi(atom);
            if ((n<-32768) || (n>65535))
            {
              errCodeList[errIdx]=INTEGER_OUT_OF_RANGE;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              if (n<0) n+=65536;
              sprintf(hexVal,"%04X",n);
              objData[dataAddr][0]=hexVal[0];
              objData[dataAddr][1]=hexVal[1];
              objData[dataAddr][2]=hexVal[2];
              objData[dataAddr][3]=hexVal[3];
              objData[dataAddr][4]='\0';
              ram[dataAddr]='1';
              dataAddr++;
            }
          }
          if (latom[0]=='$')
          {
            /* printf("data is hexadecimal sequence\n");*/
            l=(strlen(latom)-1)/4;
            if ((dataAddr+l)>8192)
            {
              errCodeList[errIdx]=OVERFLOW;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
            else
            {
              if (zHexData(objData,ram,latom,&dataAddr)==0)
              {
                errCodeList[errIdx]=INVALID_NUMBER;
                strcpy(errArgList[errIdx],atom);
                errLine[errIdx]=lineNb;
                errIdx++;
              }
            }
          }
          if (latom[0]=='*')
          {
            if (isInteger(latom+1)==1)
            {
              n=atoi(latom+1);
              /* printf("allocating block of %d words\n",n);*/
              if ((dataAddr+n)>8192)
              {
                errCodeList[errIdx]=OVERFLOW;
                strcpy(errArgList[errIdx],atom);
                errLine[errIdx]=lineNb;
                errIdx++;
              }
              else dataAddr+=n;
            }
            else
            {
              errCodeList[errIdx]=INVALID_NUMBER;
              strcpy(errArgList[errIdx],atom);
              errLine[errIdx]=lineNb;
              errIdx++;
            }
          }
          if (latom[0]=='"')
          {
            /* printf("data is character string\n");*/
            if (zStringData(fSource,objData,ram,&dataAddr)==0)
            {
              errCodeList[errIdx]=STRING_TOO_LONG;
              errLine[errIdx]=lineNb;
              errIdx++;
            }
          }
          /* printf("New dataAddr: %d\n",dataAddr);*/
          if (curVarAddr==dataAddrSaved)
          {
            curVarAddr=dataAddr;
          }
          cmpState=GLOBAL;
          break;
        }

        if (errIdx==45)
        {
          fileRead=0;
          /* too many errors => give up */
          fIdx=nbFiles;
          maxErr=1;
        }

        /* check if indexes are within limits */
        if ((flIdx==1000) || (vIdx==300) || (cIdx==300)|| (wIdx==80) ||
            (pc>8150) || (ietStkPtr==20) || (dlStkPtr==20) || (buStkPtr==20))
        {
          errCodeList[errIdx]=OVERFLOW;
          strcpy(errArgList[errIdx],fileList[fIdx]);
          errLine[errIdx]=lineNb;
          errIdx++;
          /* give up */
          fileRead=0;
          fIdx=nbFiles;
          maxErr=1;
        } 

        /* debug */
        /* printf("%d %s %s %d %d %d %d\n",lineNb,atom,latom,cmpState,cmpSavedState,fIdx,nbFiles); */
        /* scanf("%s",dum); */
      }
      /* end of file reading */

      if (cmpSavedState!=GLOBAL)
      {
        errCodeList[errIdx]=UNEXPECTED_END;
        strcpy(errArgList[errIdx],fileList[fIdx]);
        errLine[errIdx]=lineNb;
        errIdx++;
      } 
      fclose(fSource);
      fIdx++;
    }
  }
  /* complete last 16-bit word
  if (it==1) zCode(objCode,rom,"00",&pc,&it,2);

  /* end of 1st pass */
  if (errIdx>0)
  {
    for (i=0;i<errIdx;i++)
    {
      switch (errCodeList[i])
      {
        case FILE_NOT_FOUND:
          sprintf(errMsg,"Source file %s not found\n",errArgList[i]);
          break;
        case UNEXPECTED_END: 
          sprintf(errMsg,"Unexpected end of file %s\n",errArgList[i]);
          break;
        case INTEGER_OUT_OF_RANGE:
          sprintf(errMsg,"Line %d : Integer %s out of range\n",errLine[i],errArgList[i]);
          break;
        case INVALID_WORD_NAME:
         sprintf(errMsg,"Line %d : Invalid word %s (too long or already used in base dictionary)\n", errLine[i],errArgList[i]);
         break;
        case INVALID_VARIABLE_NAME:
         sprintf(errMsg,"Line %d : Invalid variable %s (too long or already used in base dictionary)\n", errLine[i],errArgList[i]);
         break;
        case INVALID_CONSTANT_NAME:
         sprintf(errMsg,"Line %d : Invalid constant %s (too long or already used in base dictionary)\n", errLine[i],errArgList[i]);
         break;
        case INVALID_STRUCT:
          sprintf(errMsg,"Line %d : Invalid structure (%s misplaced)\n",errLine[i],errArgList[i]);
          break;
        case INVALID_DATA_ADDRESS:
          sprintf(errMsg,"Line %d : Invalid address %s for data declaration\n",errLine[i],errArgList[i]); 
          break;
        case INVALID_NUMBER:
          sprintf(errMsg,"Line %d : Invalid number %s used for data declaration\n",errLine[i],errArgList[i]); 
          break;
        case STRING_TOO_LONG:
          sprintf(errMsg,"Line %d : Character-string too long (probably \" missing at the end)\n",errLine[i]); 
          break;
        case OVERFLOW:
          sprintf(errMsg,"Line %d : Memory overflow after %s declaration\n",errLine[i],errArgList[i]);
          break;
      }
      printf("%s",errMsg);
    }
    if (maxErr==1) printf("Stopped here. There might be more errors...\n");
  }

  /* 2nd pass */

  printf("Start pass 2...\n");
  /* check labels are not declared twice
     variables and constants can be declared twice only if
     they are local and in different scopes */
  if (errIdx==0)
  {
    /* check variable vs. variable */
    for (i=0;i<(vIdx-1);i++)
    {
      for (j=(i+1);j<vIdx;j++)
      {
        if ((strcmp(varTable[i],varTable[j])==0) &&
            ((strcmp(varScopeTable[i],varScopeTable[j])==0) ||
             (strcmp(varScopeTable[i],"global")==0) ||
             (strcmp(varScopeTable[j],"global")==0))) break;
      }
      if (j<vIdx)
      {
        printf("Variable %s (scope: %s) declared more than once\n",varTable[i],varScopeTable[i]);
        errIdx++;
      }
    }
    for (i=0;i<vIdx;i++)
    {
      /* check variable vs. constant */
      for (j=0;j<cIdx;j++)
      {
        if ((strcmp(varTable[i],cstTable[j])==0) &&
            ((strcmp(varScopeTable[i],cstScopeTable[j])==0) ||
             (strcmp(varScopeTable[i],"global")==0) ||
             (strcmp(cstScopeTable[j],"global")==0))) break;
      }
      if (j<cIdx)
      {
        printf("%s used for both variable and constant\n",varTable[j]);
        errIdx++;
      }
      /* check variable vs. word */
      for (j=0;j<wIdx;j++)
      {
        if (strcmp(varTable[i],wordTable[j])==0) break;
      }
      if (j<wIdx)
      {
        printf("%s used for both variable and word\n",varTable[j]);
        errIdx++;
      }
    }
    /* check word vs. word */
    for (i=0;i<(wIdx-1);i++)
    {
      for (j=(i+1);j<wIdx;j++)
      {
        if (strcmp(wordTable[i],wordTable[j])==0) break; 
      } 
      if (j<wIdx)
      {
        printf("Word %s declared more than once\n",wordTable[i]);
        errIdx++;
      }
    }
    /* check word vs. constant */
    for (i=0;i<wIdx;i++)
    {
      for (j=0;j<cIdx;j++)
      {
        if (strcmp(wordTable[i],cstTable[j])==0) break;
      }
      if (j<cIdx)
      {
        printf("%s used for both word and constant\n",varTable[j]);
        errIdx++;
      }
    } 
    /* check constant vs. constant */
    for (i=0;i<(cIdx-1);i++)
    {
      for (j=(i+1);j<cIdx;j++)
      {
        if ((strcmp(cstTable[i],cstTable[j])==0) &&
            ((strcmp(cstScopeTable[i],cstScopeTable[j])==0) ||
             (strcmp(cstScopeTable[i],"global")==0) ||
             (strcmp(cstScopeTable[j],"global")==0))) break;
      }
      if (j<cIdx)
      {
        printf("Constant %s (scope: %s) declared more than once\n",cstTable[i],cstScopeTable[i]);
        errIdx++;
      }
    }


    /* label resolution */
  
    for (i=0;i<flIdx;i++)
    {
      if (strcmp(fndLabelTable[i],fndLabelScopeTable[i])==0)
      {
        printf("Recursive call of word %s is not allowed\n",fndLabelTable[i]);
        errIdx++;
      }
      for (j=0;j<vIdx;j++)
      {
        /* printf("%s (%s) vs. %s (%s)\n",fndLabelTable[i],fndLabelScopeTable[i],varTable[j],varScopeTable[j]);*/
        if ((strcmp(fndLabelTable[i],varTable[j])==0)  &&
          ((strcmp(varScopeTable[j],"global")==0) ||
           (strcmp(varScopeTable[j],fndLabelScopeTable[i])==0))) break;
      }
      if (j<vIdx)
      {
        /* printf("Solved %s (variable)\n",fndLabelTable[i]); */
        zValue(objCode,varAddr[j],fndLabelAddr[i]);
      }
      else
      {
        for (j=0;j<cIdx;j++)
        {
          if ((strcmp(fndLabelTable[i],cstTable[j])==0)  &&
              ((strcmp(cstScopeTable[j],"global")==0) ||
               (strcmp(cstScopeTable[j],fndLabelScopeTable[i])==0))) break;
        }
        if (j<cIdx)
        {
           /* printf("Solved %s (constant)\n",fndLabelTable[i]); */ 
          zValue(objCode,cstValue[j],fndLabelAddr[i]);
        }
        else
        {
          for (j=0;j<wIdx;j++)
          {
            if (strcmp(fndLabelTable[i],wordTable[j])==0) break;
          }
          if (j<wIdx)
          {
            /* printf("Solved %s (word)\n",fndLabelTable[i]);*/
            zValue(objCode,wordAddr[j],fndLabelAddr[i]);
            /* code CAL to word (if needed) */
            pc2=fndLabelAddr[i]+2;
            it2=0;
            zCode(objCode,rom,"2B",&pc2,&it2,0);
          }
          else
          {
            printf("Label %s not declared as a word or variable\n",fndLabelTable[i]);
            errIdx++;
          }
        } 
      }
    }       
  }

  if (errIdx==0)
  {
    /* set jump to main word at boot */

    for (i=0;i<wIdx;i++)
    {
      if (strcmp(wordTable[i],"main")==0) break;
    }
    if (i<wIdx) zValue(objCode,wordAddr[i],3);
    else
    {
      printf("No main word declared\n");
      errIdx++;
    }
  }

  /* write .mif files */

  if (errIdx==0)
  {
    printf("Compilation succesful !\n");
    writeFile("ram_h.mif",objData,ram,0);
    writeFile("ram_l.mif",objData,ram,1);
    writeFile("rom.mif",objCode,rom,2);
  }

  /* debug */
  /*
  for (i=0;i<nbFiles;i++)
  {
    printf("Source file: %s\n",fileList[i]);
  }
  for (i=0;i<vIdx;i++)
  {
    printf("Declared variable: %s (scope: %s, address: %04X)\n",varTable[i],varScopeTable[i],varAddr[i]);
  }
  for (i=0;i<wIdx;i++)
  {
    printf("Declared word: %s\n",wordTable[i]);
  }
  printf("\nZTH1 code:\n");
  printf("==========\n");
  for (i=512;i<pc;i++)
  {
    printf("%04X : %s\n",i,objCode[i]);
  }*/
}
          

/* convert uppercase to lowercase (Forth words, variables and
   constants are case-insensitive */

void locase(char *sOut,char *sIn)
{
  int i,l;
  char c;

  l=strlen(sIn);
  for (i=0;i<l;i++)
  {
    c=sIn[i];
    if ((c>='A') && (c<='Z')) c+=32;
    sOut[i]=c;
  }
  sOut[l]='\0';
}

/* extract "atom" (Forth word but not only) from source file
   atoms are separated by spaces. tabs, carriage returns...
*/

int getAtom(FILE *f,char *a,int *l)
{
  char c;
  int done,ln,i,r;

  ln=*l;
  done=0;
  while (done==0)
  {
    c=getc(f);
    if (c==EOF)
    {
      /* printf("EOF 1 !\n"); */
      done=1;
    }
    if ((c>32) && (c<=126)) done=1;
    if (c==10) ln++;
  }
  if (c!=EOF)
  {
    a[0]=c;
    i=1;
    done=0;
    while (done==0)
    {
      c=getc(f);
      if (c==EOF)
      {
        /* printf("EOF 2 !\n");*/
        done=1;
      }
      if ((c>0) && (c<=32)) done=1;
      if ((c>32) && (c<=126))
      {
        a[i]=c;
        i++;
      }
    }
    a[i]='\0';
    /* move back 1 char (to count the right number of lines) */
    fseek(f,-1,SEEK_CUR);
    r=1;
  }
  else
  {
    r=0; 
  }
  *l=ln;
  return(r); 
} 


/* check if string is an integer (positive or negative) */
    
int isInteger(char *a)
{
  int x,i,l;

  l=strlen(a); 
  x=1; 
  for (i=0;i<l;i++)
  {
    if ((a[i]=='-') || (a[i]=='+'))
    {
      if ((i!=0) || (l<2)) x=0;
    }
    else
    {
      if ((a[i]<'0') || (a[i]>'9')) x=0;
    }
  }
  return(x);
}

/* check if declared word or variable name is valid
   (not an integer, not already in the base dictionary)
*/

int validWord(char *a,char **baseWord)
{
  int i,x;

  x=1;
  if (strlen(a)>39) x=0;
  if (isInteger(a)) x=0;
  if (a[0]=='$') x=0;
  for (i=0;i<NB_BASE_WORDS;i++)
  {
    if (strcmp(baseWord[i],a)==0) x=0;
  }
  if (strcmp(a,";")==0) x=0;
  if (strcmp(a,":")==0) x=0;
  if (strcmp(a,"var")==0) x=0;
  if (strcmp(a,"variable")==0) x=0;
  if (strcmp(a,"cst")==0) x=0;
  if (strcmp(a,"constant")==0) x=0;

  return(x); 
}  

    
/* Write ZTH1 op-code sequence into ROM */

void zCode(char **objCode,char *mem,char *opCode,int *pcPtr,int *itPtr,int its)
{
  int i,n,pc,it;
  char s[80];

  strcpy(s,"");
  pc=*pcPtr;
  it=*itPtr;

  if ((its==0) || (its==1))
  {
    /* NOP padding */
    if (it!=its) strcpy(s,"00");
  }
  strcat(s,opCode);
  n=strlen(s)/2;
  for (i=0;i<n;i++)
  {
    if (it==0)
    {
      objCode[pc][0]=s[2*i];
      objCode[pc][1]=s[2*i+1];
      mem[pc]='1'; 
      it=1;
    }
    else
    {
      objCode[pc][2]=s[2*i];
      objCode[pc][3]=s[2*i+1];
      objCode[pc][4]='\0';
      mem[pc]='1'; 
      it=0;
      pc++;
    }
  }
  *pcPtr=pc;
  *itPtr=it;
}

/* Write 16-bit value into ROM (corresponding to PSH xx LDL yy code) */

void zValue(char **objCode,int n,int pc)
{
  char hexVal[5];

  sprintf(hexVal,"%04X",n);
  objCode[pc][2]=hexVal[0];
  objCode[pc][3]=hexVal[1];
  objCode[pc+1][2]=hexVal[2];
  objCode[pc+1][3]=hexVal[3];
}
       
/* Write object (.mif) file */

int writeFile(char *name,char **obj,char *mem,int b)
{
  FILE *fo;
  char v[5];
  int i,j,k,r;

  r=1;
  fo=fopen(name,"w");
  if (fo==NULL)
  {
    printf("Cannot create file %s\n",name);
    r=-1;
  }
  if (b==2)
  {
    fprintf(fo,"WIDTH=16;\n");
  }
  else
  {
    fprintf(fo,"WIDTH=8;\n");
  }
  fprintf(fo,"DEPTH=8192;\n\n");
  fprintf(fo,"ADDRESS_RADIX=HEX;\n");
  fprintf(fo,"DATA_RADIX=HEX;\n\n");
  fprintf(fo,"CONTENT BEGIN\n\n");

  i=0;
  while (i<8192)
  {
    k=0;
    if (mem[i]=='0')
    {
      /* see if block of 0s has to be written */
      if ((mem[i+1]=='0') && (i<8192))
      {
        j=i;
        while((mem[i]=='0') && (i<8192)) i++;
        k=1;
      }
    }
    if (k==1)
    {
      i--;
      if (b==2)
      {
        fprintf(fo,"[%04X..%04X] : 0000;\n",j,i);
      }
      else
      {
        fprintf(fo,"[%04X..%04X] : 00;\n",j,i);
      }
    }
    else
    {
      if (mem[i]=='0') strcpy(obj[i],"0000");
      switch (b)
      {
        case 0: v[0]=obj[i][0];
                v[1]=obj[i][1];
                v[2]='\0';
                break;
        case 1: v[0]=obj[i][2];
                v[1]=obj[i][3];
                v[2]='\0';
                break;
        case 2: v[0]=obj[i][0];
                v[1]=obj[i][1];
                v[2]=obj[i][2];
                v[3]=obj[i][3];
                v[4]='\0';
                break;
      }
      fprintf(fo,"%04X : %s;\n",i,v);
    }
    i++;
  }
  fprintf(fo,"END;\n");
  fclose(fo);
  return(r);
}

 
/* Read object (.mif) file (OS)  */

int readFile(char *name,char **obj,char *mem,int b)
{
  FILE *fi;
  char l[80];
  char hx[5];
  int i,r,x;
  int done;
  int start,stop;

  r=1;
  fi=fopen(name,"r");
  if (fi==NULL)
  {
    printf("Cannot open file %s\n",name);
    r=-1;
  }
  if (r!=-1)
  {
    /* skip 8 first lines (= header) */
    for (i=0;i<8;i++) readLine(fi,l);
    done=0;
    while (done==0)
    {
      if (readLine(fi,l)==0) done=1;
      if (l[0]=='E') done=1;
      if (done==0) 
      {
        /* printf("%s\n",l); */
        if (l[0]=='[')
        {
          hx[0]=l[1]; hx[1]=l[2]; hx[2]=l[3]; hx[3]=l[4]; hx[4]='\0';
          start=hex2dec(hx);
          hx[0]=l[7]; hx[1]=l[8]; hx[2]=l[9]; hx[3]=l[10]; hx[4]='\0';
          stop=hex2dec(hx);
          x=15;
        }
        else
        {
          hx[0]=l[0]; hx[1]=l[1]; hx[2]=l[2]; hx[3]=l[3]; hx[4]='\0';
          start=hex2dec(hx);
          stop=start;
          x=7;
        }
        hx[0]=l[x]; hx[1]=l[x+1]; 
        if (b==2)
        {
          hx[2]=l[x+2]; hx[3]=l[x+3]; hx[4]='\0'; 
        }
        else
        {
          hx[3]='\0';
        }
        /* printf("%d %d\n",start,stop);*/
        for (i=start;i<=stop;i++)
        {
          switch (b)
          {
            case 0: obj[i][0]=hx[0]; obj[i][1]=hx[1]; obj[i][4]='\0';
                    break;
            case 1: obj[i][2]=hx[0]; obj[i][3]=hx[1]; obj[i][4]='\0';
                    break;
            case 2: obj[i][0]=hx[0]; obj[i][1]=hx[1];
                    obj[i][2]=hx[2]; obj[i][3]=hx[3]; obj[i][4]='\0';
          }
          /* we assume intervals only contain 0 (unused words) */
          if (start==stop) mem[i]='1';
        }
      }
    }
    fclose(fi);
  }
  return(r);
}  

/* read line from file */

int readLine(FILE *f,char *s)
{
  char c;
  int i,r,done;

  done=0;
  i=0;
  r=1;
 
  while (done==0)
  {
    c=getc(f);
    if (c==EOF)
    {
      r=0;
      done=1;
    }
    else if (c=='\n')
    {
      done=1;
    }
    else
    {
      s[i]=c;
      i++;
    }
  }
  s[i]='\0';
  return(r);
}

/* convert hexadecimal number in string to integer
   return 100000 (out of range) if string does not represent an integer
   hexadecimal numbers are case-insensitive */
 
int hex2dec(char *s)
{
  char c;
  int i,l,x;

  x=0;
  l=strlen(s);

  for (i=0;i<l;i++)
  {
    c=s[i];
    if ((c>='0') && (c<='9')) x=16*x+(int)c-48;
    else if ((c>='A') && (c<='F')) x=16*x+(int)c-55;
    else if ((c>='a') && (c<='f')) x=16*x+(int)c-87;
    else x=100000;
  }
  return(x);
} 
   
/* Write a sequence of hexadecimal values into data */
 
int zHexData(char **objData,char *ram,char *latom,int *dataAddr)
{
  int a,i,j,l,r;

  r=1;
  l=strlen(latom)-1;
  if (l%4!=0) r=0;
  else
  {
    for (i=1;i<=l;i++)
    {
      r=0;
      if ((latom[i]>='a') && (latom[i]<='f'))
      {
        latom[i]=latom[i]-32;
        r=1;
      }
      if ((latom[i]>='0') && (latom[i]<='9')) r=1;
    }
  }
  if (r==1)
  {
    a=*dataAddr;
    l=l/4;
    j=1;
    for (i=0;i<l;i++)
    {
      objData[a][0]=latom[j];
      objData[a][1]=latom[j+1];
      objData[a][2]=latom[j+2];
      objData[a][3]=latom[j+3];
      objData[a][4]='\0';
      ram[a]='1';
      j=j+4;
      a++;
    }
    *dataAddr=a;
  }
  return(r);
}

/* read a character string (ending with ") from source file */

int zStringData(FILE *f,char **objData,char *mem,int *dataAddr)
{
  int a,r;
  char c;
  int done;
  int it;
  char hexVal[3];
 
  a=*dataAddr; 
  done=0;
  /* skip first spaces, tabs, cr.. */
  while (done==0)
  {
    c=getc(f);
    if (c==EOF)
    {
      done=1;
      r=0;
    }
    if ((c>32) && (c<128))
    {
      done=1;
      r=1;
    }
  }
  if (r==1)
  {
    it=0;
    sprintf(hexVal,"%02X",(int)c);
    objData[a][0]=hexVal[0];
    objData[a][1]=hexVal[1];
    mem[a]='1';
    it++;
    done=0;
    while (done==0)
    {
      c=getc(f);
      if (c==EOF)
      {
        done=1;
        r=0;
      }
      else if (c=='"')
      {
        done=1;
        if (it==0)
        {
          objData[a][0]='0';
          objData[a][1]='0';
          mem[a]='1';
        }
        objData[a][2]='0';
        objData[a][3]='0';
        a++;
      }
      else if ((c>=32) && (c<128))
      {
        sprintf(hexVal,"%02X",(int)c);
        if (it==0)
        {
          objData[a][0]=hexVal[0];
          objData[a][1]=hexVal[1];
          mem[a]='1';
          it++;
        }
        else
        {
          objData[a][2]=hexVal[0];
          objData[a][3]=hexVal[1];
          a++;
          it=0;
        }
        if (a>8192)
        {
          r=0;
          done=1;
          a=DATA_START_ADDR;
        }
      }
    }
  }
  *dataAddr=a;
  return(r);
}  
      
    
 
