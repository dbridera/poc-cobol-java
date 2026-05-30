       IDENTIFICATION DIVISION.                                                 
      *************************                                                 
                                                                                
       PROGRAM-ID.    BCTITPRA.                                                 
       AUTHOR.        TCS -                                                     
       INSTALLATION.  BANCO DE CREDITO.                                         
       DATE-WRITTEN.  OCT - 2021.                                               
      ******************************************************************        
      *                    PROPIEDAD DEL PROGRAMA                      *        
      *                                                                *        
      *   ESTE PROGRAMA Y SUS ELEMENTOS ASOCIADOS SON DE PROPIEDAD     *        
      *   DEL BANCO DE CREDITO DEL PERU Y NO PUEDE SER REPRODUCIDO,    *        
      *   DIVULGADO O UTILIZADO SIN UNA LICENCIA O AUTORIZACION        *        
      *   ESCRITA OTORGADA POR EL BANCO DE CREDITO DEL PERU.           *        
      *                                                                *        
      ******************************************************************        
      * SISTEMA   : TTIB  - TRANSFERENCIAS INTERBANCARIAS              *        
      *                                                                *        
      * MODULO    : SOLICITUD ESTADO DE PAGO                           *        
      *                                                                *        
      * OBJETIVOS : REINTENTO DE TRAMA DE REGULARIZACION Y RESPUESTA   *        
      *             CLIENTE                                            *        
      *                                                                *        
      * FUNCIONES : 1. LEE ARCHIVO DE PENDIENTES RECEPTOR              *        
      *                                                                *        
      *             2. BUSCA REGISTRO EN MAESTRO DE TRANSACCIONES      *        
      *                                                                *        
      *             3. ENVIA TRAMA A DISTRIBUIDO                       *        
      *                                                                *        
      *             4. SEGUN RESPUESTA ENVIA TRAMA A PROGRAMA          *        
      *                TRANSFERENCIA RECEPTOR                          *        
      *                                                                *        
      *             5. ACTUALIZA REGISTRO DE MAESTRO TRANSACCIONAL Y   *        
      *                ARCHIVO DE PENDIENTES.                          *        
      *                                                                *        
      * NRO.TICKET    :  TA000184143                                   *00160022
      *                                                                *        
      ******************************************************************00071352
      *                       CONTROL DE CAMBIOS                       *00071352
      ******************************************************************00069579
      * MODIFICACION  : VOCALINK USUARIO TETI REINTENTOS               *        
      * FECHA         : JUNIO 2022                                     *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: TCS                                            *        
      * NRO.TICKET    : MVP00103948                                    *        
      ******************************************************************00160022
      * MODIFICACION  : INCLUSION DE ENVIO TRAMA PARA TOPICO           *00160022
      * FECHA         : 17-03-2023                                     *00160022
      * AFECTA A      : REINTENTOS RECEPTOR                            *00160022
      * MODIFICADO POR: TCS - JCS                                      *00160022
      * NRO.TICKET    : MVP00128827                                    *00160022
      ******************************************************************00160022
      ******************************************************************        
      * MODIFICACION  : COMPLETA VALORES FALTANTES DE DATOS            *        
      * FECHA         : 30-05-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00139677                                    *        
      ******************************************************************        
      **********************                                                    
       ENVIRONMENT DIVISION.                                                    
      **********************                                                    
      ***************                                                           
       DATA DIVISION.                                                           
      ***************                                                           
      *************************                                                 
       WORKING-STORAGE SECTION.                                                 
      *************************                                                 
       01  WS-VARIABLES-GENERALES.                                              
           05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPRA'.          
           05  WS-RTN-SGTE               PIC  X(08)  VALUE SPACES.              
           05  WS-PROG-CALLER            PIC  X(08)  VALUE 'BCTITPRA'.          
           05  WS-PROG-TTIB-R            PIC  X(08)  VALUE 'BCTITPR8'.          
           05  WS-RTN-MENSAJES           PIC  X(08)  VALUE 'BCTITP15'.          
           05  WS-USUARIO                PIC  X(07)  VALUE '       '.           
           05  WS-EYEID-ND               PIC  X(10)  VALUE 'NEXTDAYCOM'.        
           05  WS-APLID-SYST             PIC  X(04)  VALUE 'TTIB'.              
           05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV04'.          
           05  WS-ABSTIME                PIC S9(15) COMP-3 VALUE +0.            
           05  WS-FECH-PROC              PIC  X(10)        VALUE ' '.           
           05  WS-ABPROGRAM              PIC  X(08) VALUE SPACES.               
           05  WS-ABCODE                 PIC  X(04) VALUE SPACES.               
           05  WS-CF06-IMPORTE-ORIGINAL  PIC S9(14)V9999.                       
           05  WS-ESTADO-NEXT-DAY        PIC  9(08) VALUE ZEROES.       00160022
           05  WS-FIN-PEND               PIC  X(01) VALUE 'N'.                  
           05  WS-CONTADORES-FILES.                                     00160022
               10  WS-NC-COUNTER-NAME    PIC  X(16)  VALUE SPACES.      00160022
               10  WS-NM-COUNTER-VALOR   PIC S9(08)  COMP  VALUE +0.    00160022
      *                                                                         
           05  WS-FLAG-NEXT-DAY          PIC  9(01)  VALUE 0.           00160022
               88  WS-CURRENT-DAY                    VALUE 0.           00160022
               88  WS-IN-PROCESS                     VALUE 7.           00160022
               88  WS-NEXT-DAY                       VALUE 9.           00160022
                                                                        00160022
       01  WS-FILE-NAME-TTIB.                                           00160022
           05  WS-FILE-NM-MAESTRO          PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT      PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT2     PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-PENDREC             PIC  X(08)  VALUE SPACES.    00160022
                                                                                
       01  WS-VARIABLES-ERROR.                                                  
           05  WS-VARMSG-FUN             PIC  X(20)  VALUE SPACES.              
           05  WS-VARMSG-RSO             PIC  X(20)  VALUE SPACES.              
           05  WS-VARMSG-ARG             PIC  X(20)  VALUE SPACES.              
           05  WS-VARMSG-TXT             PIC  X(30)  VALUE SPACES.              
           05  WS-VARMSG-OPE             PIC  X(20)  VALUE SPACES.              
           05  WS-PROGRAM-ERROR          PIC  X(08)  VALUE 'BCTITPRA'.          
                                                                                
       01  WS-SWITCHES.                                                         
           05  WS-ENQ-RESOURCE         PIC X(01) VALUE 'N'.                     
               88  WS-ENQ-RESOURCE-NO            VALUE 'N'.                     
               88  WS-ENQ-RESOURCE-SI            VALUE 'S'.                     
                                                                                
       01  WS-RESOURCE.                                                         
           05  WS-RESOURCE-BCP         PIC X(03) VALUE 'BCP'.                   
           05  WS-RESOURCE-PROG        PIC X(08) VALUE SPACES.                  
           05  WS-RESOURCE-KEY-TRANSF  PIC X(41) VALUE SPACES.                  
                                                                                
           05  WS-CLAVE-PEND             PIC  X(41).                            
                                                                                
           05  WS-HORA-PROCESO.                                                 
               10 WS-HORA-HH             PIC  X(02).                            
               10 WS-FILL-HH             PIC  X(01).                            
               10 WS-HORA-MM             PIC  X(02).                            
               10 WS-FILL-MM             PIC  X(01).                            
               10 WS-HORA-SS             PIC  X(02).                            
                                                                                
           05  WS-FECHA-PROC             PIC X(10).                             
           05  WS-LGTH-CCAA              PIC S9(04) COMP VALUE 0.               
JCS   *    05  WS-CCAA                   PIC X(3000).                           
JCS        05  WS-CCAA                   PIC X(5000).                           
           05  WS-LENGTH-TSEP-TRAMA      PIC S9(14).                            
      *                                                                         
           05  WS-FECHA-LOCAL            PIC  9(08) VALUE 0.                    
           05  WS-HORA-LOCAL             PIC  9(06) VALUE 0.                    
           05  WS-FECHA-INI.                                                    
               10  WS-FEINI-CICS         PIC  9(08) VALUE 0.                    
               10  FILLER                PIC  X(02) VALUE SPACES.               
           05  WS-HORA-INI.                                                     
               10  WS-HOINI-CICS         PIC  X(08) VALUE SPACES.               
           05  WS-NUM-SEGUNDOS           PIC S9(08) COMP  VALUE +1.             
           05  WS-HORA-SS-INI            PIC 9(05).                             
           05  WS-HORA-SS-CSEP           PIC 9(05).                             
           05  WS-TIEMPO-PROC            PIC 9(05).                             
      *MVP00103948-I                                                    00160022
           05  WS-INTERV-REI             PIC 9(08) COMP VALUE ZEROS.            
      *MVP00103948-F                                                    00160022
                                                                                
           05 WS-HORA-CORTE.                                                    
              10 WS-HORA-C               PIC 99 VALUE ZEROES.                   
              10 WS-HORA-M               PIC 99 VALUE ZEROES.                   
                                                                                
           05 WS-HORA-CICS-EDT.                                                 
              10 WS-HORA-EDT-HH          PIC 99 VALUE ZEROES.                   
              10 FILLER                  PIC X(01)  VALUE ':'.                  
              10 WS-HORA-EDT-MM          PIC 99 VALUE ZEROES.                   
              10 FILLER                  PIC X(01)  VALUE ':'.                  
              10 WS-HORA-EDT-SS          PIC 99 VALUE ZEROES.                   
                                                                                
           05 WS-HORA-CICS-INI.                                                 
              10 WS-HORA-INI-HH          PIC 99 VALUE ZEROES.                   
              10 FILLER                  PIC X(01)  VALUE ':'.                  
              10 WS-HORA-INI-MM          PIC 99 VALUE ZEROES.                   
              10 FILLER                  PIC X(01)  VALUE ':'.                  
              10 WS-HORA-INI-SS          PIC 99 VALUE ZEROES.                   
                                                                                
           05  WS-RESP                   PIC S9(08)  COMP VALUE +0.             
           05  WS-RESP2                  PIC S9(08)  COMP VALUE +0.             
           05  WS-RESP2-NOTFND           PIC S9(08) COMP VALUE +201.    00160022
           05  WS-LGTH-TEM               PIC S9(04) COMP VALUE 0.               
           05  WS-PTR-TSIS-N             PIC S9(08) COMP VALUE 0.               
           05  WS-PTR-TSIS-X   REDEFINES                                        
               WS-PTR-TSIS-N             PIC  X(04).                            
           05  WS-PTR-TSIS     REDEFINES                                        
               WS-PTR-TSIS-N              USAGE IS POINTER.                     
                                                                                
           05  WS-PTR-COMM             USAGE IS POINTER.                        
                                                                                
           05  WS-RECURSOS-CICS.                                                
               10  WS-TIPO-CONEX         PIC  X(02) VALUE '  '.                 
                   88  WS-CONEX-LINK         VALUE  'D ' 'DS'.                  
                   88  WS-CONEX-START        VALUE  'S ' 'SD' 'SZ'.             
                   88  WS-CONEX-TRIGGER      VALUE  'QD'.                       
                   88  WS-CONEX-SEND         VALUE  'TD'.                       
                   88  WS-CONEX-TASK         VALUE  'U '.                       
               10  WS-TRANID             PIC  X(04) VALUE SPACES.               
               10  WS-CONVID             PIC  X(04) VALUE SPACES.               
               10  WS-APPLID             PIC  X(08) VALUE SPACES.               
                                                                                
           05  WS-SYSID-LOC              PIC  X(04) VALUE SPACES.               
           05  WS-REINTENTO-TTIB         PIC  9(02) VALUE ZEROS.                
                                                                                
       01  WS-NEW-MESSAGE.                                                      
           03  WS-HDR-MESSAGE.                                                  
               05  WS-HDR-BYTEI         PIC  X(05) VALUE 'ByteI'.               
               05  WS-HDR-DATE-DDMMAAAA PIC  X(08) VALUE SPACES.                
               05  WS-HDR-TIME-HHMM     PIC  X(04) VALUE SPACES.                
               05  WS-HDR-EVENT         PIC  X(05) VALUE SPACES.                
               05  WS-HDR-USER          PIC  X(10) VALUE SPACES.                
           03  WS-BODY-MSGDEI           PIC  X(2025) VALUE SPACES.              
           03  WS-TRAILER-MSGDEI        PIC  X(05)   VALUE 'ByteF'.             
                                                                                
       01  WS-CONSTANTES.                                                       
           05  WS-CT-TI                  PIC X(02) VALUE 'TI'.                  
           05  WS-CT-RECHAZADO           PIC X(02) VALUE '05'.                  
           05  WS-CT-HORA-INI            PIC X(04) VALUE '1555'.                
           05  WS-CT-HORA-FIN            PIC X(04) VALUE '1605'.                
                                                                                
       01  WS-RPTA-MSG-CCE.                                                     
           05  WS-CODMSG-CCE.                                                   
               10  WS-COD-CCE            PIC  X(02).                            
               10  WS-COD-CCE-AMPLI      PIC  X(04).                            
           05 WS-MSG-CCE                 PIC  X(80).                            
                                                                                
       01  WS-RPTA-MSG-BCP.                                                     
           05  WS-CODMSG-ESTRUCTURA.                                            
               10  WS-CODAPP             PIC  X(02)  VALUE 'TI'.                
               10  WS-CODTIP             PIC  X(02).                            
                   88  WS-CODTIP-88-CONFORME         VALUE '00'.                
                   88  WS-CODTIP-88-ERROR-CONSIST    VALUE '04'.                
                   88  WS-CODTIP-88-ERROR-RECURSOS   VALUE '08'.                
                   88  WS-CODTIP-88-ERROR-AUTORIZ    VALUE '16'.                
               10  WS-CODMSG-SEC         PIC  X(02).                            
           05  WS-TXTMSG                 PIC  X(80)  VALUE SPACES.              
                                                                                
       01  WS-ERROR-MAESTRO.                                                    
           05  FILLER                    PIC  X(36)  VALUE                      
                        'ERROR AL LEER ARCHIVO BCTIMSTF RESP='.                 
           05  WS-RESP-ED                PIC -ZZZZZZ99.                         
           05  FILLER                    PIC  X(07)  VALUE ' RESP2='.           
           05  WS-RESP2-ED               PIC -ZZZZZZ99.                         
      *                                                                         
           05  WS-NRO-SESSION-ID         PIC S9(08)  COMP  VALUE +0.            
           05  WS-NRO-SESSION-ID-ED      PIC ZZZZZZZZ.                          
           05  WS-NRO-SESSION-ID-TXT     PIC  X(08)  VALUE SPACES.              
           05  WS-NRO-SESSION-ID-TMP     PIC  X(08)  VALUE SPACES.              
           05  WS-NRO-SESSION-ID-SPA     PIC  X(08)  VALUE SPACES.              
      *                                                                         
                                                                                
       01  WS-REG-GRABAR-CSMT.                                                  
           05  WS-CSMT-COD-APLIC-04      PIC  X(04)  VALUE 'TTIB'.              
           05  FILLER                    PIC  X(01)  VALUE SPACES.              
           05  WS-CSMT-COD-PROGRAMA      PIC  X(08)  VALUE 'BCTITPRA'.          
           05  FILLER                    PIC  X(01)  VALUE SPACES.              
           05  WS-CSMT-RESPUESTA.                                               
               10  WS-CSMT-COD-RETORNO   PIC  X(08)  VALUE SPACES.              
               10  WS-CSMT-MENSAJE       PIC  X(78)  VALUE SPACES.              
      *                                                                         
       01  WS-SWITCHES.                                                         
                                                                                
           05  WS-SI-REG-MAYOR           PIC  X(01)  VALUE 'N'.                 
                                                                                
           05  ERROR-REG-MAESTRO         PIC  X(01)  VALUE 'N'.                 
               88  ERROR-REG-MAESTRO-N               VALUE 'N'.                 
               88  ERROR-REG-MAESTRO-S               VALUE 'S'.                 
                                                                                
           05  WS-HUBO-ERROR             PIC  X(01)  VALUE 'N'.                 
                                                                                
           05  WS-EXISTE-ERROR-ANT       PIC  X(01)  VALUE 'N'.                 
               88  WS-NO-EXISTE-ERROR-ANT            VALUE 'N'.                 
               88  WS-SI-EXISTE-ERROR-ANT            VALUE 'S'.                 
                                                                                
           05  WS-EXISTE-ERROR-CCE       PIC  X(01)  VALUE 'N'.                 
               88  WS-NO-EXISTE-ERROR-CCE            VALUE 'N'.                 
               88  WS-SI-EXISTE-ERROR-CCE            VALUE 'S'.                 
                                                                                
           05  WS-EXISTE-ERROR-GRAL      PIC  X(01)  VALUE 'N'.                 
               88  WS-NO-ERROR-GRAL                  VALUE 'N'.                 
               88  WS-SI-ERROR-GRAL                  VALUE 'S'.                 
                                                                                
           05  WS-EXISTE-ERROR           PIC  X(01)  VALUE 'N'.         00069579
               88  WS-NO-EXISTE-ERROR                VALUE 'N'.         00069579
               88  WS-SI-EXISTE-ERROR                VALUE 'S'.         00069579
                                                                        00069579
       01  WS-CODIGOS-ERRORES.                                                  
           05  WS-COD-E-ACCESO-MAESTRO    PIC  X(04) VALUE '0020'.              
           05  WS-COD-E-DUP-RECORD        PIC  X(04) VALUE '0021'.              
           05  WS-COD-E-ARCHIVO-LOG       PIC  X(04) VALUE '0022'.              
           05  WS-COD-E-LINK-GRAL         PIC  X(04) VALUE '0023'.              
           05  WS-COD-E-NEXT-PROC         PIC  X(04) VALUE '0024'.              
           05  WS-COD-E-ASKTIME           PIC  X(04) VALUE '0025'.              
           05  WS-COD-E-INTERNO-BCTITP80  PIC  X(04) VALUE '0027'.              
           05  WS-COD-E-IMPORTE-SUP       PIC  X(04) VALUE '0028'.              
           05  WS-COD-E-LOG-EVENTOS       PIC  X(04) VALUE '0029'.              
           05  WS-COD-E-TRAMA-TRANS       PIC  X(04) VALUE '0030'.              
           05  WS-COD-E-FILE-PARAMETROS   PIC  X(04) VALUE '0031'.              
           05  WS-COD-E-ACCESS-FILE       PIC  X(04) VALUE '0032'.              
           05  WS-COD-E-CURRENT-DAY       PIC  X(04) VALUE '0033'.              
           05  WS-COD-E-NEXT-DAY          PIC  X(04) VALUE '0034'.              
           05  WS-COD-E-LINK-NEXT-DAY     PIC  X(04) VALUE '0035'.              
           05  WS-COD-E-TRAMA-OTRO        PIC  X(04) VALUE '0036'.              
           05  WS-COD-E-OBT-LINK          PIC  X(04) VALUE '0037'.              
           05  WS-COD-E-CARGAR-TABLA      PIC  X(04) VALUE '0038'.              
           05  WS-COD-E-NO-FOUND-PAR      PIC  X(04) VALUE '0039'.              
           05  WS-COD-E-LINK-BCTITP80     PIC  X(04) VALUE '0036'.              
                                                                                
       01  WS-DESCRIPCION-ERRORES.                                              
           05  WS-88-ERROR-FORMATTIME    PIC  X(80) VALUE                       
               'ERROR EN FORMATTIME                                   '.        
           05  WS-88-ERROR-CARGA-TSIS    PIC  X(80) VALUE                       
               'ERROR AL CARGAR LA TABLA DEL SISTEMA                  '.        
           05  WS-88-ERROR-COMMAREA      PIC  X(80) VALUE                       
               'ERROR AL OBTENER CONEXION                             '.        
           05  WS-88-ERROR-CANAL-INV     PIC  X(80) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.        
           05  WS-88-ERROR-TIP-PAGO      PIC  X(80) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.        
           05  WS-88-ERROR-COD-MON       PIC  X(80) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.        
           05  WS-88-ERROR-TIP-TRN       PIC  X(80) VALUE                       
               'NEXT DAY EN PROCESO                                   '.        
           05  WS-ERROR-INTERNO-BCTITP80 PIC  X(80) VALUE                       
               'NEXT DAY INICIO                                       '.        
           05  WS-88-ERROR-ACTUALIZ      PIC  X(80) VALUE                       
               'ERROR AL OBTENER COUNTER                              '.        
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(80) VALUE                      
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.        
           05  WS-88-ERROR-TRAMA-CONS    PIC  X(80) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.        
           05  WS-88-ERROR-CONS-INCOR    PIC  X(80) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.        
           05  WS-88-ERROR-RANGO-NO-FOUND PIC  X(80) VALUE                      
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.        
           05  WS-88-ERROR-RANGO-MENOR   PIC  X(80) VALUE                       
               'NEXT DAY EN PROCESO                                   '.        
           05  WS-88-ERROR-ACCESO-MAESTRO PIC  X(80) VALUE                      
               'NEXT DAY INICIO                                       '.        
           05  WS-88-ERROR-DUP-RECORD    PIC  X(80) VALUE                       
               'ERROR AL OBTENER COUNTER                              '.        
           05  WS-88-ERROR-ARCHIVO-LOG    PIC  X(80) VALUE                      
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.        
           05  WS-88-ERROR-LINK-GRAL      PIC  X(80) VALUE                      
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.        
           05  WS-88-ERROR-NEXT-PROC     PIC  X(80) VALUE                       
               'NEXT DAY EN PROCESO                                   '.        
           05  WS-88-ERROR-ASKTIME        PIC  X(80) VALUE                      
               'NEXT DAY INICIO                                       '.        
           05  WS-88-ERROR-REGISTRO-NO-FOUND PIC X(80) VALUE                    
               'ERROR AL OBTENER COUNTER                              '.        
           05  WS-88-ERROR-READ-UBIGEO    PIC  X(80) VALUE                      
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.        
           05  WS-88-ERROR-IMPORTE-SUP    PIC  X(80) VALUE                      
               'IMPORTE SUPERIOR                                      '.        
           05  WS-88-ERROR-GRABAR-LOGEVEN PIC  X(80) VALUE                      
               'ERROR AL GRABAR EN LOG DE EVENTOS               '.              
           05  WS-88-ERROR-TRAMA-TRANS    PIC  X(80) VALUE                      
               'ERROR EN TRAMA DE TRANSFERENCIA                 '.              
           05  WS-88-ERROR-FILE-PARAMETROS  PIC  X(80) VALUE                    
               'ERROR AL LEER ARCHIVO DE PARAMETROS             '.              
           05  WS-88-ERROR-ACCESS-FILE      PIC X(80) VALUE                     
               'ERROR AL GRABAR EN MAESTRO DE TRANSACCIONES     '.              
           05  WS-88-ERROR-CURRENT-DAY     PIC  X(70) VALUE                     
               'LA INTERFAZ TTIB SOLO FUNCIONA EN MODO CURRENT DAY '.           
           05  WS-88-ERROR-NEXT-DAY      PIC  X(70) VALUE                       
               'EL MODO DE PROCESO (NEXT DAY), NO PUDO SER DETERMINADO'.        
           05  WS-88-ERROR-LINK-NEXT-DAY PIC  X(70) VALUE                       
               'ERROR AL ACCEDER AL PROGRAMA DE NEXT DAY              '.        
           05  WS-88-ERROR-TRAMA-OTRO    PIC  X(70) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.        
           05  WS-88-ERROR-OBT-LINK      PIC  X(70) VALUE                       
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.        
           05  WS-88-ERROR-CARGAR-TABLA  PIC  X(70) VALUE                       
               'ERROR AL CARGAR LA TABLA DEL SISTEMA                  '.        
           05  WS-88-ERROR-NO-FOUND-PAR  PIC  X(70) VALUE                       
               'REGISTRO NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS    '.        
           05  WS-88-ERROR-LINK-BCTITP80 PIC  X(70) VALUE                       
               'ERROR AL HACER LINK AL PROGRAMA BCTITP80              '.        
                                                                                
      *                                                                         
       01  WS-COD-ORIG.                                                         
           10  WS-COD-RESP              PIC X(04).                              
           10  FILLER                   PIC X(01) VALUE SPACES.                 
           10  WS-ORI-RESP              PIC X(03).                              
      *                                                                         
      ******************************************************************        
      *                COPYBOOKS Y COMMAREAS DE TRABAJO                *        
      ******************************************************************        
      *--------------  ARCHIVO MAESTRO DE TRANSACCIONES                         
       COPY BCTICF06.                                                           
                                                                                
      *--------------  TRAMA 01 STANDARD - MONITOR DEI                          
       COPY BCMDCD01.                                                           
                                                                                
      *--------------  COPY DE CABECERA ESTANDAR                                
       COPY BCRGCA10.                                                           
                                                                                
      *--------------  ORQUESTADOR DE TRANSFERENCIAS E INTERMEDIACION           
       COPY BCOQTR27.                                                           
      *                                                                         
      *-------------   OBTENER DINAMICAMENTE EL AMBIENTE DE EJECUCION           
      *COPY BCRGCA05.                                                           
      *                                                                         
                                                                        02080000
      *-------------   COMMAREA DE PROGRAMA BCTITP80                    01990010
       COPY BCTICA80.                                                   02000010
                                                                        02010010
      *-------------   REGISTRO DE PARAMETROS                           01990010
       COPY BCTICF01.                                                   02000010
                                                                                
      *--------------  ESTRUCUTRA DEL LOG DE EVENTOS                            
       COPY BCTICF07.                                                           
                                                                                
      *--------------  AREA DE COMUNICACION RUTINA MENSAJES                     
       COPY BCTICA15.                                                           
                                                                                
      *--------------  AREA DE COMUNICACION DEL ADAPTADOR - MQ                  
       COPY BCMQYR08.                                                           
                                                                                
      * DATA AREA FOR LINK TO MQSeries ACCESS RTN.  L=32700 PREF: BT-MQS        
       01  BT-MQS-PARMS-AREA           PIC  X(32700).                           
       COPY MQSPARM.                                                    00069579
      *----------------------------------------------------------------*00069579
                                                                                
      *--------------  archivo de pendientes                                    
       COPY BCTICSEP.                                                           
      *                                                                         
      *--------------  TRAMA INPUT/OUTPUT                                       
       COPY BCTITPSR.                                                           
                                                                                
      *--------------  TRAMA INPUT PROGRAMA RECEPTOR                            
       COPY BCTITRR2.                                                           
TOPICO*MVP00128827--\                                                           
      *--------------  TRAMA INPUT/OUTPUT **                                    
       COPY BCTITRE2.                                                           
TOPICO*MVP00128827--/                                                           
                                                                                
      *****************                                                         
       LINKAGE SECTION.                                                         
      *****************                                                         
       01  DFHCOMMAREA                 PIC  X(01).                              
                                                                                
      *--------------  TABLA DEL SISTEMA DPLZ                                   
       COPY BCTICW04.                                                           
                                                                                
      ********************                                                      
       PROCEDURE DIVISION.                                                      
      ********************                                                      
                                                                                
           IF EIBTRNID NOT EQUAL 'TISP'                                         
              PERFORM 7000-TERMINAR                                             
           END-IF                                                               
                                                                                
           PERFORM  1000-INICIO                                                 
                                                                                
      *MVP00103948-I                                                            
      *    PERFORM  2010-LEEFILE-PENDIENTES                                     
           IF WS-FIN-PEND = 'N'                                                 
               PERFORM  2010-LEEFILE-PENDIENTES                                 
           END-IF                                                               
      *MVP00103948-F                                                            
                                                                                
           PERFORM  2000-PROCESO UNTIL WS-FIN-PEND = 'S'                        
                                                                                
           PERFORM  3000-FINAL                                                  
           .                                                                    
                                                                                
       1000-INICIO.                                                             
      *----------------------------------------------------------------*        
      * INICIO PROCESO                                                 *        
      *----------------------------------------------------------------*        
                                                                                
           EXEC  CICS                                                           
                                                                                
               HANDLE ABEND                                                     
                      LABEL (9999-MANEJO-EXCEPCIONES)                           
                                                                                
           END-EXEC                                                             
                                                                                
           PERFORM  1100-OBTIENE-SYSID                                          
           PERFORM  1020-OBTIENE-FECHA-HORA-INICIO                              
           PERFORM  1110-CARGA-TABLA-SIST-TTIB                                  
           PERFORM  2001-STARBR-PENDIENTES                                      
           .                                                                    
                                                                                
      *--------------------------------------------------FIN DE INICIO-*        
                                                                                
       1100-OBTIENE-SYSID.                                                      
      *----------------------------------------------------------------*        
      * OBTIENE EL SYSID DEL CICS DONDE SE EJECUTA EL PROGRAMA         *        
      *----------------------------------------------------------------*        
                                                                                
            EXEC  CICS  ASSIGN                                                  
                 INVOKINGPROG (WS-PROG-CALLER)                                  
                    STARTCODE (WS-TIPO-CONEX)                                   
                        SYSID (WS-SYSID-LOC)                                    
                       USERID (WS-USUARIO)                                      
                         RESP (WS-RESP)                                         
                        RESP2 (WS-RESP2)                                        
            END-EXEC                                                            
                                                                                
            IF  WS-RESP     NOT EQUAL TO    DFHRESP(NORMAL)                     
               SET  WS-SI-ERROR-GRAL            TO TRUE                         
               SET  WS-SI-EXISTE-ERROR-ANT      TO TRUE                         
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                         
               MOVE 02                     TO WS-CODMSG-SEC                     
               MOVE WS-RESP                TO WS-CSMT-COD-RETORNO               
               MOVE 'INVOKINGPROG '        TO WS-CSMT-MENSAJE                   
               PERFORM 3000-FINAL                                               
            END-IF                                                              
           .                                                                    
      *--------------------------------------------FIN DE OBTIENE-SYSID*        
      *                                                                         
       1020-OBTIENE-FECHA-HORA-INICIO.                                          
      *----------------------------------------------------------------*        
      * RECUPERAMOS LA FECHA Y HORA DE INICIO  DESDE EL CICS.          *        
      *----------------------------------------------------------------*        
                                                                                
             EXEC  CICS  ASKTIME                                                
                         ABSTIME (WS-ABSTIME)                                   
                         RESP (WS-RESP)                                         
                         RESP2 (WS-RESP2)                                       
             END-EXEC                                                           
                                                                                
             IF  WS-RESP     NOT EQUAL TO    DFHRESP(NORMAL)                    
                 SET  WS-SI-ERROR-GRAL            TO TRUE                       
                 SET  WS-SI-EXISTE-ERROR-ANT      TO TRUE                       
                 SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                       
                 MOVE 02                          TO WS-CODMSG-SEC              
                 MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO        
                 MOVE 'ASKTIME'                   TO WS-CSMT-MENSAJE            
                 PERFORM 3000-FINAL                                             
             END-IF                                                             
                                                                                
             EXEC  CICS  FORMATTIME                                             
                          ABSTIME (WS-ABSTIME)                                  
                         YYYYMMDD (WS-FECHA-INI)                                
                             TIME (WS-HORA-INI)                                 
                          TIMESEP                                               
                             RESP (WS-RESP)                                     
                            RESP2 (WS-RESP2)                                    
             END-EXEC                                                           
                                                                                
             IF  WS-RESP     NOT EQUAL TO    DFHRESP(NORMAL)                    
                 SET  WS-SI-ERROR-GRAL            TO TRUE                       
                 SET  WS-SI-EXISTE-ERROR-ANT      TO TRUE                       
                 SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                       
                 MOVE 02                          TO WS-CODMSG-SEC              
                 MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO        
                 MOVE 'FORMATTIME'                TO WS-CSMT-MENSAJE            
                 PERFORM 3000-FINAL                                             
             ELSE                                                               
                 MOVE WS-HORA-INI TO WS-HORA-CICS-EDT                           
                                     WS-HORA-CICS-INI                           
                 MOVE WS-HORA-EDT-HH TO WS-HORA-C                               
                 MOVE WS-HORA-EDT-MM TO WS-HORA-M                               
                 COMPUTE WS-HORA-SS-INI = (WS-HORA-EDT-HH * 3600) +             
                                          (WS-HORA-EDT-MM * 60)   +             
                                           WS-HORA-EDT-SS                       
             END-IF                                                             
           .                                                                    
      *--------------------------*                                              
       1110-CARGA-TABLA-SIST-TTIB.                                              
      *----------------------------------------------------------------*        
      * OBTIENE EL SYSID DE LA REGION CICS DONDE SE EJECUTA EL PRGM. Y *        
      * CARGA  LA TABLA DEL SYSTEMA TTIB                               *        
      *----------------------------------------------------------------*        
                                                                                
           SET  WS-NO-EXISTE-ERROR               TO TRUE                00160022
                                                                                
           PERFORM  5500-OBTENER-TABLA-TTIB                             00160022
                                                                        00160022
           PERFORM  5510-OBTENER-SESSION-ID                             00160022
                                                                        00160022
           PERFORM  5600-OBTENER-ESTADO-TTIB                            00160022
                                                                        00160022
           IF  TI-CW04-88-CURRENT-DAY                                   00160022
               OR  TI-CW04-88-NEXT-DAY                                  00160022
               MOVE TI-CW04-FILE-REINTENTOS-RE  TO WS-FILE-PENDREC      00160022
               EVALUATE  TRUE                                           00160022
                   WHEN WS-CURRENT-DAY                                  00160022
                       MOVE TI-CW04-FILE-MAESTRO                        00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT                    00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT2                   00160022
                                           TO WS-FILE-NM-MAESTRO-ALT2   00160022
                                                                        00160022
                   WHEN WS-NEXT-DAY                                     00160022
                       MOVE TI-CW04-FILE-MAESTRO-NDAY                   00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT-NDAY               00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
                       MOVE TI-CW04-FILE-MAESTRO-AL2-NDAY               00160022
                                           TO WS-FILE-NM-MAESTRO-ALT2   00160022
                                                                        00160022
               END-EVALUATE                                             00160022
                                                                        00160022
           ELSE                                                                 
               SET  WS-SI-EXISTE-ERROR          TO TRUE                 00160022
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 00160022
               MOVE 01                          TO WS-CODMSG-SEC        00160022
               MOVE 'NEXT DAY CURRENT DAY'      TO WS-CSMT-MENSAJE              
               PERFORM 3000-FINAL                                               
                                                                        00160022
           END-IF                                                               
           .                                                                    
                                                                                
      *                                                                         
      *-------------*                                                   00069579
       2000-PROCESO.                                                            
      *----------------------------------------------------------------*        
      * REALIZA LAS VERIFICACIONES NECESARIAS Y PROCESA LA CONSULTA             
      *----------------------------------------------------------------*        
                                                                                
           MOVE 'N'     TO    WS-HUBO-ERROR                                     
           IF TI-CSEP-NUMERO-REINTENTOS  < TI-CW04-DAT-CANT-MAX-RE              
              AND WS-SI-REG-MAYOR = 'S'                                         
              AND TI-CSEP-COD-PROCESO  EQUAL 'TRN'                              
              PERFORM 2300-ARMA-TRAMA-ENVIA                                     
              IF WS-HUBO-ERROR EQUAL 'N'                                        
                 PERFORM 2400-VALIDA-RESPUESTA                                  
              END-IF                                                            
           END-IF                                                               
           PERFORM 2010-LEEFILE-PENDIENTES                                      
           .                                                                    
      *----------------------------------------------------------------*        
       2001-STARBR-PENDIENTES.                                                  
      *----------------------------------------------------------------*        
      *                                                                         
      *MVP00103948-I                                                            
           MOVE  'N'                   TO WS-FIN-PEND                           
      *MVP00103948-F                                                            
           MOVE  SPACES                TO WS-CLAVE-PEND                         
                                                                                
           EXEC  CICS STARTBR FILE   (WS-FILE-PENDREC)                          
                              RIDFLD (WS-CLAVE-PEND)                            
                              KEYLENGTH (LENGTH OF WS-CLAVE-PEND)               
                              GTEQ                                              
                              RESP   (WS-RESP)                                  
                              RESP2  (WS-RESP2)                                 
           END-EXEC                                                             
           EVALUATE WS-RESP                                                     
                WHEN  DFHRESP(NORMAL)                                           
                   CONTINUE                                                     
      *MVP00103948-I                                                            
                WHEN  DFHRESP(NOTFND)                                           
                   MOVE 'S'                    TO WS-FIN-PEND                   
      *MVP00103948-F                                                            
                WHEN OTHER                                                      
                   SET  WS-SI-EXISTE-ERROR     TO TRUE                          
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
                   MOVE 07                     TO WS-CODMSG-SEC                 
                   MOVE WS-FILE-PENDREC        TO WS-CSMT-MENSAJE               
      *MVP00103948-I                                                            
                   MOVE 'STARTBR'              TO WS-CSMT-MENSAJE(10:)          
      *MVP00103948-F                                                            
                   MOVE WS-RESP                TO WS-CSMT-COD-RETORNO           
                   PERFORM 3000-FINAL                                           
           END-EVALUATE                                                         
           .                                                                    
      *----------------------------------------------------------------*        
       2010-LEEFILE-PENDIENTES.                                                 
      *----------------------------------------------------------------*        
      * LEE SIGUIENTE REGISTRO PENDIENTES                             *         
      *----------------------------------------------------------------*        
      *                                                                         
           MOVE  'N'    TO   WS-SI-REG-MAYOR                                    
                                                                                
           EXEC  CICS                                                           
                 READNEXT   FILE   (WS-FILE-PENDREC)                            
                            INTO   (TI-CSEP-REG-TRANS)                          
                            LENGTH (LENGTH OF TI-CSEP-REG-TRANS)                
                            RIDFLD (WS-CLAVE-PEND)                              
                            RESP   (WS-RESP)                                    
                            RESP2  (WS-RESP2)                                   
           END-EXEC                                                             
                                                                                
           EVALUATE WS-RESP                                                     
                WHEN DFHRESP(NORMAL)                                            
                   PERFORM 2021-VALIDA-MINUTOS                                  
                WHEN DFHRESP(ENDFILE)                                           
                   MOVE  'S'   TO  WS-FIN-PEND                                  
      *MVP00103948-I                                                            
      *         WHEN DFHRESP(NOTFND)                                            
      *            MOVE 'LEE ARCHIVO BCTIFSEP:VACIO'                            
      *                                        TO WS-CSMT-MENSAJE               
      *            SET WS-SI-EXISTE-ERROR      TO TRUE                          
      *            SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
      *            PERFORM 3000-FINAL                                           
      *MVP00103948-F                                                            
                WHEN OTHER                                                      
                   SET  WS-SI-EXISTE-ERROR     TO TRUE                          
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
                   MOVE 07                     TO WS-CODMSG-SEC                 
                   MOVE WS-RESP                TO WS-CSMT-COD-RETORNO           
                   MOVE WS-FILE-PENDREC        TO WS-CSMT-MENSAJE               
      *MVP00103948-I                                                            
                   MOVE 'READNEXT'             TO WS-CSMT-MENSAJE(10:)          
      *MVP00103948-F                                                            
                   PERFORM 3000-FINAL                                           
           END-EVALUATE                                                         
           .                                                                    
      *-------------------*                                             00069579
       2021-VALIDA-MINUTOS.                                                     
      *-------------------*                                             00069579
           PERFORM 1020-OBTIENE-FECHA-HORA-INICIO                               
           MOVE TI-CSEP-HORA-TRANS-HH  TO WS-HORA-EDT-HH                        
           MOVE TI-CSEP-HORA-TRANS-MM  TO WS-HORA-EDT-MM                        
           MOVE TI-CSEP-HORA-TRANS-SS  TO WS-HORA-EDT-SS                        
           COMPUTE WS-HORA-SS-CSEP = (WS-HORA-EDT-HH * 3600) +                  
                                     (WS-HORA-EDT-MM * 60)   +                  
                                      WS-HORA-EDT-SS                            
           COMPUTE WS-TIEMPO-PROC = WS-HORA-SS-INI -                            
                                    WS-HORA-SS-CSEP                             
           IF WS-TIEMPO-PROC > TI-CW04-TIME-FILE-TTIB                           
              MOVE   'S'   TO   WS-SI-REG-MAYOR                                 
           END-IF                                                               
           .                                                                    
                                                                        00069579
      *---------------------*                                           00069579
       2300-ARMA-TRAMA-ENVIA.                                                   
      *----------------------------------------------------------------*        
      * MOVER CAMPOS ARCHIVO PENDIENTES A LA TRAMA RECEPTOR                     
      *    INICIALIZA TRAMA                                                     
           INITIALIZE TI-TPSR-IO-TRAMA                                          
                       REPLACING  ALPHANUMERIC DATA BY SPACES                   
                                  NUMERIC DATA BY ZEROS                         
           MOVE WS-HORA-INI-HH              TO WS-HORA-LOCAL(1:2)               
           MOVE WS-HORA-INI-MM              TO WS-HORA-LOCAL(3:2)               
           MOVE WS-HORA-INI-SS              TO WS-HORA-LOCAL(5:2)               
           MOVE WS-FEINI-CICS(1:4)          TO WS-FECHA-LOCAL(1:4)              
           MOVE TI-CSEP-FECHA-TRANS         TO WS-FECHA-LOCAL(5:4)              
           MOVE 'TIRS'                      TO TI-TPSR-SERV                     
           MOVE TI-CSEP-REQUEST-ID          TO TI-TPSR-REQUEST                  
           MOVE TI-CSEP-CODIGO-BCO-RECPTOR  TO TI-TPSR-ENTIDAD-RECEP            
           MOVE WS-FEINI-CICS               TO TI-TPSR-CREA-DATE                
           MOVE WS-HORA-LOCAL               TO TI-TPSR-CREA-TIME                
           MOVE TI-CSEP-INSTRUCTION-ID      TO TI-TPSR-INSTR-ID                 
           MOVE TI-CSEP-CURRENCY            TO TI-TPSR-CURRENCY                 
           MOVE WS-FECHA-LOCAL              TO TI-TPSR-ORIC-DATE                
           MOVE TI-CSEP-HORA-TRANS   TO  TI-TPSR-ORIC-TIME                      
           COMPUTE WS-REINTENTO-TTIB = TI-CSEP-NUMERO-REINTENTOS        00160022
                                       + 1                              00160022
           MOVE WS-REINTENTO-TTIB           TO TI-TPSR-NRO-REINTENTOS           
           PERFORM 2301-ARMA-HEADER-MQ                                          
           PERFORM 2302-ENVIA-MQ                                                
           .                                                                    
      *-------------------*                                             00069579
       2301-ARMA-HEADER-MQ.                                                     
      *---------------------*                                           00069579
      *                                                                         
           MOVE SPACES                TO BCMQYR08                               
           MOVE ZEROS                 TO BCMQYR08-COD-RETORNO                   
           MOVE ZEROS                 TO BCMQYR08-COD-DETALLE                   
           MOVE +0                    TO BCMQYR08-LMENSAJE                      
           MOVE ZEROS                 TO BCMQYR08-TMENSAJE                      
                                                                                
           MOVE WS-CT-TI              TO BCMQYR08-COD-APL-SOLIC                 
           MOVE 'P'                   TO BCMQYR08-COD-INST                      
           MOVE SPACES                TO BCMQYR08-COD-SERVICIO                  
           MOVE TI-TPSR-SERV          TO BCMQYR08-COD-INTERF                    
           MOVE 'PSHGSH'              TO BCMQYR08-GLS-ACCION                    
           MOVE  0                    TO BCMQYR08-COD-RETORNO                   
           MOVE  0                    TO BCMQYR08-COD-DETALLE                   
           MOVE  TI-TPSR-IO-TRAMA     TO BCMQYR08-MENSAJE               00069579
           COMPUTE BCMQYR08-LMENSAJE   = LENGTH OF TI-TPSR-IO-TRAMA             
           .                                                                    
      *-------------*                                                   00069579
       2302-ENVIA-MQ.                                                           
      *-------------*                                                   00069579
           MOVE TI-CW04-PGM-MQ                TO WS-RTN-SGTE                    
           MOVE BCMQYR08                      TO WS-CCAA                        
           MOVE LENGTH OF BCMQYR08            TO WS-LGTH-CCAA                   
                                                                                
           PERFORM  7200-RUT-LINK-GRAL                                          
                                                                                
           MOVE WS-CCAA                       TO BCMQYR08                       
                                                                                
              EVALUATE BCMQYR08-COD-RETORNO                                     
                 WHEN 00                                                        
                      MOVE LENGTH OF TI-TPSR-IO-TRAMA  TO                       
                                      WS-LENGTH-TSEP-TRAMA                      
                      MOVE BCMQYR08-MENSAJE(1:WS-LENGTH-TSEP-TRAMA) TO          
                                         TI-TPSR-IO-TRAMA                       
                      MOVE 'N'                         TO WS-HUBO-ERROR         
                 WHEN 03                                                        
                      SET  WS-SI-EXISTE-ERROR          TO TRUE                  
                      SET  WS-CODTIP-88-CONFORME       TO TRUE                  
                      MOVE 01                          TO WS-CODMSG-SEC         
                      MOVE 'N'                         TO WS-HUBO-ERROR         
                 WHEN OTHER                                                     
                      SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                  
                      MOVE 12                          TO WS-CODMSG-SEC         
                      MOVE 'S'                         TO WS-HUBO-ERROR         
                      MOVE TI-CW04-PGM-MQ        TO WS-CSMT-MENSAJE             
                      MOVE BCMQYR08-COD-RETORNO  TO WS-CSMT-COD-RETORNO         
                      PERFORM 3000-FINAL                                        
              END-EVALUATE                                                      
           .                                                                    
TOPICO*MVP00128827--\                                                           
      *-----------------*                                               00069579
       2303-TRAMA-TOPICO.                                                       
      *-----------------*                                               00069579
      *                                                                         
           INITIALIZE  TI-TRE2-I-TRAMA                                          
                       REPLACING  ALPHANUMERIC DATA BY SPACES                   
                                  NUMERIC DATA BY ZEROS                         
           MOVE 'TIRR'                    TO TI-TRE2-CODIGO-SERVICIO            
           MOVE '0201'                    TO TI-TRE2-MSGE-TYPE-ID               
           MOVE TI-CSEP-HORA-TRANS        TO TI-TRE2-FECHA-HORA-PROC            
      *    MOVE TI-CSEP-FECHA-TRANS       TO TI-TRE2-FECHA-PROCESO              
           MOVE TI-CSEP-INSTRUCTION-ID(01:08)                                   
                                       TO TI-TRE2-FECHA-PROCESO                 
           MOVE TI-CSEP-CANAL-CCE         TO TI-TRE2-CANAL                      
           MOVE TI-CSEP-TRACE-ADQUIRIENTE TO TI-TRE2-TRACE-ADQUIRIENTE          
           MOVE TI-TRR2-RESPONSE-CODE-CCE TO TI-TRE2-RESPONSE-CODE-CCE          
           MOVE TI-CSEP-TERMINAL-ID       TO TI-TRE2-TERMINAL-ID                
           MOVE TI-TRR2-COD-RESP-AMPLIADO TO TI-TRE2-COD-RESP-AMPLIADO          
           MOVE TI-CSEP-TRA-EXT           TO TI-TRE2-TRANS-EXTENDIDA            
           MOVE TI-CSEP-IMPORTE           TO TI-TRE2-IMPORTE                    
           MOVE TI-CSEP-COD-TAR-CRE       TO TI-TRE2-CODIGO-TARIFA              
           MOVE TI-TRR2-CRITERIO-APLICACION                                     
                                       TO TI-TRE2-CRITERIO-APLICACION           
           MOVE TI-TRR2-REF-TRANSFERENCIA TO TI-TRE2-REF-TRANSFERENCIA          
                                                                                
           MOVE TI-TRR2-ENTIDAD-ORIGEN   TO TI-TRE2-ENTIDAD-ORIGEN              
           MOVE TI-TRR2-CCI-CLI-ORIGINANTE  TO                                  
                                         TI-TRE2-CCI-CLI-ORIGINANTE             
           MOVE TI-TRR2-TIPO-PERSONA     TO TI-TRE2-TIPO-PERSONA                
           MOVE TI-TRR2-TIP-DOC-CLI-ORIG TO                                     
                                         TI-TRE2-TIP-DOC-CLI-ORIG               
           MOVE TI-TRR2-NRO-DOC-CLI-ORIG TO                                     
                                         TI-TRE2-NRO-DOC-CLI-ORIG               
           MOVE TI-TRR2-NOM-APE-ORIG     TO                                     
                                      TI-TRE2-APE-PAT-RAZ-SOC-CLI-OR            
           MOVE TI-TRR2-DIRECC-CLI-ORIG  TO                                     
                                         TI-TRE2-DIRECC-CLI-ORIG                
           MOVE TI-TRR2-TELEF-CLI-ORIG   TO TI-TRE2-NRO-FIJO-CLI-ORIG           
           MOVE TI-TRR2-NRO-CEL-CLI-ORIG TO                                     
                                         TI-TRE2-NRO-CEL-CLI-ORIG               
                                                                                
           MOVE TI-TRR2-ENTIDAD-DESTINO   TO TI-TRE2-ENTIDAD-DESTINO            
           MOVE TI-TRR2-CCI-CLI-BENEFICIA TO TI-TRE2-CCI-CLI-BENEFICIA          
           MOVE TI-TRR2-COD-TARJETA-CRED  TO TI-TRE2-COD-TARJETA-CRED           
           MOVE TI-TRR2-TIP-DOC-CLI-BENE  TO TI-TRE2-TIP-DOC-CLI-BENE           
           MOVE TI-TRR2-NRO-DOC-CLI-BENE  TO TI-TRE2-NRO-DOC-CLI-BENE           
           MOVE TI-TRR2-NOM-APE-BENE                                            
                                    TO TI-TRE2-APE-PAT-RAZ-SOC-CLI-BE           
           MOVE TI-TRR2-DIRECC-CLI-BENE                                         
                                          TO  TI-TRE2-DIRECC-CLI-BENE           
           MOVE TI-TRR2-TELEF-CLI-BENE    TO  TI-TRE2-TELEF-CLI-BENE            
                                                                                
                                                                        08519000
      *    STRING  '+51'  TI-TRR2-NRO-CEL-CLI-BENE                      08519000
      *       DELIMITED  BY  SIZE       INTO  TI-TRE2-NRO-CEL-CLI-BENE  08519000
JCS   *MVP00139677--\                                                           
           MOVE TI-TRR2-NRO-CEL-CLI-BENE   TO TI-TRE2-NRO-CEL-CLI-BENE  08519000
           MOVE TI-TRR2-TRANS-CURREN-CODE  TO TI-TRE2-TRANS-CURREN-CODE 08519000
JCS   *MVP00139677--/                                                           
                                                                        08519000
           MOVE TI-TRR2-INDI-MISMO-CLIENTE TO                                   
                                           TI-TRE2-INDI-MISMO-CLIENTE           
           MOVE TI-TRR2-CANAL              TO TI-TRE2-CANAL-BCP                 
           MOVE TI-TRR2-GLOSA              TO TI-TRE2-GLOSA-I                   
           MOVE TI-TRR2-GLOSA-BCP          TO TI-TRE2-GLOSA-BCP                 
           MOVE TI-TRR2-REF-INSTRUCTION-ID TO                                   
                                           TI-TRE2-REF-INSTRUCTION-ID           
           MOVE TI-TRR2-INSTRUCTION-ID     TO TI-TRE2-INSTRUCTION-ID            
           MOVE TI-TRR2-REF-INSTRUCTION-ID                                      
                                        TO TI-TRE2-CON-INSTRUCTION-ID           
           MOVE TI-TRR2-NUMERO-REINTENTOS  TO TI-TRE2-INDI-REINTENTO            
           MOVE TI-TRR2-REQUEST-ID         TO TI-TRE2-REQUEST-ID                
           MOVE TI-TRR2-MONTO-LIQUIDACION  TO                                   
                                       TI-TRE2-MONTO-LIQUIDAC-INTERB            
           MOVE TI-TRR2-FECHA-LIQUIDACION TO TI-TRE2-FECHA-LIQUIDACION          
           MOVE TI-TRR2-RESPONSE-DATE     TO TI-TRE2-FECHA-RESPUESTA            
           MOVE TI-TRR2-RESPONSE-TIME     TO                                    
                                          TI-TRE2-FECHA-HORA-RESPUESTA          
JCS   *MVP00139677--\                                                           
           MOVE TI-TRR2-LIBRE-RECEPTOR(01:02)                                   
                                          TO TI-TRE2-CANAL-BCP                  
           MOVE SPACES                    TO TI-TRR2-LIBRE-RECEPTOR             
           MOVE TI-TRR2-CON-INSTRUCTION-ID                                      
                                       TO TI-TRE2-CON-INSTRUCTION-ID            
           MOVE SPACES                    TO TI-TRE2-VALOR-PROXY                
                                             TI-TRE2-TIPO-PROXY                 
                                             TI-TRE2-FILLER                     
JCS   *MVP00139677--/                                                           
                                                                                
           MOVE WS-CODMSG-ESTRUCTURA      TO TI-TRE2-CODMSG-ESTRUCTURA          
           MOVE WS-VARMSG-FUN             TO TI-TRE2-VARMSG-FUN                 
           MOVE WS-VARMSG-RSO             TO TI-TRE2-VARMSG-RSO                 
           MOVE WS-VARMSG-ARG             TO TI-TRE2-VARMSG-ARG                 
           MOVE WS-VARMSG-TXT             TO TI-TRE2-VARMSG-TXT                 
           MOVE WS-VARMSG-OPE             TO TI-TRE2-VARMSG-OPE                 
                                                                                
           MOVE SPACES              TO BCMQYR08                                 
           MOVE ZEROS               TO BCMQYR08-TMENSAJE                        
           MOVE ZEROS               TO BCMQYR08-COD-RETORNO                     
                                       BCMQYR08-COD-DETALLE                     
           MOVE +0                  TO BCMQYR08-LMENSAJE                        
                                                                                
           MOVE WS-CT-TI            TO BCMQYR08-COD-APL-SOLIC                   
           MOVE 'P'                 TO BCMQYR08-COD-INST                        
           MOVE SPACES              TO BCMQYR08-COD-SERVICIO                    
           MOVE 'TIRR'              TO TI-TRE2-CODIGO-SERVICIO                  
                                       BCMQYR08-COD-INTERF                      
           MOVE 'PSH   '            TO BCMQYR08-GLS-ACCION                      
           MOVE  TI-TRE2-I-TRAMA    TO BCMQYR08-MENSAJE                 00069579
           COMPUTE BCMQYR08-LMENSAJE  =                                         
                                    LENGTH OF TI-TRE2-I-TRAMA                   
                                                                                
           MOVE TI-CW04-PGM-MQ      TO WS-RTN-SGTE                              
           MOVE BCMQYR08            TO WS-CCAA                                  
           MOVE LENGTH OF BCMQYR08  TO WS-LGTH-CCAA                             
                                                                                
           PERFORM  7200-RUT-LINK-GRAL                                          
                                                                                
           MOVE WS-CCAA             TO BCMQYR08                                 
                                                                                
           EVALUATE BCMQYR08-COD-RETORNO                                        
              WHEN 00                                                           
                   MOVE LENGTH OF TI-TRE2-I-TRAMA   TO                          
                                  WS-LENGTH-TSEP-TRAMA                          
                   MOVE BCMQYR08-MENSAJE(1:WS-LENGTH-TSEP-TRAMA) TO             
                                  TI-TRE2-I-TRAMA                               
                   MOVE 'N'                         TO WS-HUBO-ERROR            
              WHEN 03                                                           
                   SET  WS-SI-EXISTE-ERROR          TO TRUE                     
                   SET  WS-CODTIP-88-CONFORME       TO TRUE                     
                   MOVE 01                          TO WS-CODMSG-SEC            
                   MOVE 'N'                         TO WS-HUBO-ERROR            
              WHEN OTHER                                                        
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
                   MOVE  'S'                        TO WS-HUBO-ERROR            
                   MOVE 12                          TO WS-CODMSG-SEC            
                   MOVE TI-CW04-PGM-MQ        TO WS-CSMT-MENSAJE                
                   MOVE BCMQYR08-COD-RETORNO  TO WS-CSMT-COD-RETORNO            
                   PERFORM 3000-FINAL                                           
           END-EVALUATE                                                         
           .                                                                    
TOPICO*MVP00128827--/                                                   00069579
                                                                                
      *---------------------*                                           00069579
       2400-VALIDA-RESPUESTA.                                                   
      *----------------------------------------------------------------*        
      * VALIDA RESPUESTA PARA ACTUALIZAR MAESTRO Y ENVIAR CORREO                
      *----------------------------------------------------------------*        
      * VALIDA LA RESPUESTA DE LA TRAMA                                         
           IF WS-CODMSG-SEC EQUAL '01' OR '12' OR                               
              TI-TPSR-CODE-RET EQUAL '99'                                       
              PERFORM 2599-VUELVE-A-LEER                                        
              PERFORM 2510-ACTUALIZA-PENDIENTES                                 
           ELSE                                                                 
                 EVALUATE TI-TPSR-CODE-RET                                      
                     WHEN  00                                                   
                        PERFORM 2420-ARMA-TRAMA-CONFIRMACION            00160022
TOPICO*MVP00139677--\                                                           
                        IF TI-TRR2-RESPONSE-CODE-CCE     = '00'                 
                           PERFORM 2303-TRAMA-TOPICO                            
                        END-IF                                                  
TOPICO*MVP00139677--/                                                           
                     WHEN  05                                                   
                        PERFORM 2430-ARMA-TRAMA-RECHAZO                 00160022
TOPICO*MVP00139677--\                                                           
                        IF TI-TRR2-RESPONSE-CODE-CCE  = '05'  AND               
                           TI-TRR2-COD-RESP-AMPLIADO  = 'DS24'                  
                           PERFORM 2303-TRAMA-TOPICO                            
                        END-IF                                                  
TOPICO*MVP00139677--/                                                           
                                                                                
      *MVP00103948-I                                                            
                     WHEN  OTHER                                                
                        MOVE 'TI-TPSR-CODE-RET'   TO WS-CSMT-MENSAJE            
                        MOVE TI-TPSR-CODE-RET     TO WS-CSMT-COD-RETORNO        
                        PERFORM 6000-WRITE-CSMT                                 
      *MVP00103948-F                                                            
                 END-EVALUATE                                                   
           END-IF                                                               
           .                                                                    
      *------------------------*                                                
       2440-ENVIA-TRANSFERENCIA.                                        00069579
      *------------------------*                                        00069579
      *---------------------------------------------------------------* 00069579
      *  LINK AL PROGRAMA BCTITPR8                                    * 00069579
      *---------------------------------------------------------------* 00069579
      *                                                                         
           MOVE WS-CLAVE-PEND         TO  WS-RESOURCE-KEY-TRANSF                
           MOVE TI-CSEP-REG-KEY-PEND  TO  WS-CLAVE-PEND                         
      *                                                                         
           EXEC CICS UNLOCK FILE (WS-FILE-PENDREC)                              
           RESP (WS-RESP)                                                       
           END-EXEC                                                             
      *                                                                         
           EVALUATE WS-RESP                                                     
                WHEN DFHRESP(NORMAL)                                            
                   CONTINUE                                                     
                WHEN OTHER                                                      
                   MOVE WS-RESP                TO WS-CSMT-COD-RETORNO           
                   MOVE WS-FILE-PENDREC        TO WS-CSMT-MENSAJE               
      *MVP00103948-I                                                            
                   MOVE 'UNLOCK'               TO WS-CSMT-MENSAJE(10:)          
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
                   MOVE 07                     TO WS-CODMSG-SEC                 
      *MVP00103948-F                                                            
                   PERFORM 3000-FINAL                                           
           END-EVALUATE                                                         
                                                                                
      *                                                                         
           EXEC CICS LINK PROGRAM(WS-PROG-TTIB-R)                       00069579
                          COMMAREA(TI-TRR2-I-TRAMA)                     00069579
                          LENGTH (LENGTH OF TI-TRR2-I-TRAMA)                    
                          RESP(WS-RESP)                                 00069579
           END-EXEC                                                     00069579
      *                                                                 00069579
           IF WS-RESP EQUAL TO DFHRESP(NORMAL)                          00069579
              IF TI-TRR2-COD-RESP-AMPLIADO EQUAL 'AM05'                         
                 PERFORM 2520-BORRA-PENDIENTES                                  
              ELSE                                                              
                  IF (TI-TRR2-COD-RESP-AMPLIADO NOT EQUAL '0000'  AND           
                      TI-TRR2-COD-RESP-AMPLIADO NOT EQUAL 'DS24')               
                     PERFORM 2599-VUELVE-A-LEER                                 
                     PERFORM 2510-ACTUALIZA-PENDIENTES                          
                  END-IF                                                        
              END-IF                                                            
           ELSE                                                         00069579
              SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                  00069579
              MOVE 'LINK BCTITPR8'             TO WS-CSMT-MENSAJE       00069579
              MOVE WS-PROG-TTIB-R              TO WS-VARMSG-RSO         00069579
              MOVE 05                          TO WS-CODMSG-SEC         00069579
              MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO   00069579
              PERFORM 3000-FINAL                                                
           END-IF                                                       00069579
           .                                                            00069579
      *                                                                         
      *-----------------------*                                         00069579
       2430-ARMA-TRAMA-RECHAZO.                                                 
      *----------------------------------------------------------------*        
      * ARMAR CABECERA PARA PROGRAMA TRANSFERENCIA RECHAZO                      
      *----------------------------------------------------------------*        
      *                                                                         
           INITIALIZE TI-TRR2-I-TRAMA                                           
                       REPLACING  ALPHANUMERIC DATA BY SPACES                   
                                  NUMERIC DATA BY ZEROS                         
           MOVE 'TIRO'                   TO TI-TRR2-COD-SERV                    
           MOVE  TI-TPSR-REQUEST         TO TI-TRR2-REQUEST-ID                  
           MOVE  TI-TPSR-ENTIDAD-RECEP   TO TI-TRR2-ENTIDAD-DESTINO             
           MOVE  TI-TPSR-CREA-DATE       TO TI-TRR2-CREATION-DATE               
           MOVE  TI-TPSR-CREA-TIME       TO TI-TRR2-CREATION-TIME               
           MOVE  TI-TPSR-CURRENCY        TO TI-TRR2-TRANS-CURREN-CODE           
           MOVE  TI-TPSR-INSTR-ID        TO TI-TRR2-INSTRUCTION-ID              
                                              TI-TRR2-REF-INSTRUCTION-ID        
      *   TI-TRR2-BRANCH-ID                                                     
           MOVE  TI-TPSR-CODE-RET        TO TI-TRR2-RESPONSE-CODE-CCE           
           MOVE  TI-TPSR-REF-TRAN        TO TI-TRR2-REF-TRANSFERENCIA           
           COMPUTE WS-REINTENTO-TTIB = TI-CSEP-NUMERO-REINTENTOS        00160022
                                       + 1                              00160022
           MOVE  WS-REINTENTO-TTIB       TO TI-TRR2-NUMERO-REINTENTOS           
           MOVE  'L'                     TO TI-TRR2-TIPO-PROCESO                
           MOVE  '01'                    TO TI-TRR2-REENVIO                     
           PERFORM 2440-ENVIA-TRANSFERENCIA                                     
           .                                                            00069579
      *                                                                         
      *----------------------------*                                    00069579
       2420-ARMA-TRAMA-CONFIRMACION.                                            
      *----------------------------------------------------------------*        
      * ARMAR CABECERA PARA PROGRAMA TRANSFERENCIA CONFIRMACION                 
      *----------------------------------------------------------------*        
      *                                                                         
           INITIALIZE TI-TRR2-I-TRAMA                                           
                       REPLACING  ALPHANUMERIC DATA BY SPACES                   
                                  NUMERIC DATA BY ZEROS                         
           MOVE 'TIRO'                   TO TI-TRR2-COD-SERV                    
           MOVE  TI-TPSR-REQUEST         TO TI-TRR2-REQUEST-ID                  
           MOVE  TI-CSEP-TRA-EXT         TO TI-TRR2-TRANS-EXTENDIDA             
           MOVE  TI-CSEP-CCI-CLI-ACR     TO TI-TRR2-CCI-CLI-BENEFICIA           
           MOVE  TI-CSEP-COD-TAR-CRE     TO TI-TRR2-COD-TARJETA-CRED            
           MOVE  TI-TPSR-ENTIDAD-ORIGEN  TO TI-TRR2-ENTIDAD-ORIGEN              
           MOVE  TI-TPSR-ENTIDAD-RECEP   TO TI-TRR2-ENTIDAD-DESTINO             
           MOVE  TI-TPSR-CREA-DATE       TO TI-TRR2-CREATION-DATE               
           MOVE  TI-TPSR-CREA-TIME       TO TI-TRR2-CREATION-TIME               
           MOVE  TI-TPSR-TERMINAL-ID     TO TI-TRR2-TERMINAL-ID                 
           MOVE  TI-TPSR-REFERENCIA      TO TI-TRR2-NRO-REFERENCIA              
           MOVE  TI-TPSR-TRACE           TO TI-TRR2-TRACE-ADQUIRIENTE           
           MOVE  TI-TPSR-CURRENCY        TO TI-TRR2-TRANS-CURREN-CODE           
JCS   *    MOVE  TI-CSEP-IMPORTE         TO TI-TRR2-IMPORTE                     
           MOVE  TI-TPSR-INSTR-ID        TO TI-TRR2-INSTRUCTION-ID              
                                            TI-TRR2-REF-INSTRUCTION-ID          
           MOVE  WS-CT-TI                TO TI-TRR2-CANAL                       
           MOVE  TI-TPSR-CODE-RET        TO TI-TRR2-RESPONSE-CODE-CCE           
           MOVE  TI-TPSR-MISMO-CLI       TO TI-TRR2-INDI-MISMO-CLIENTE          
           MOVE  TI-TPSR-AMOUNT          TO TI-TRR2-IMPORTE                     
           MOVE  TI-TPSR-REF-TRAN        TO TI-TRR2-REF-TRANSFERENCIA           
           MOVE  TI-CSEP-CCI-CLI-ORI     TO TI-TRR2-CCI-CLI-ORIGINANTE          
           MOVE  TI-TPSR-FECHA-LIQ       TO TI-TRR2-FECHA-LIQUIDACION           
           MOVE  TI-TPSR-MONTO-LIQ       TO TI-TRR2-MONTO-LIQUIDACION           
           MOVE  TI-TPSR-RESP-DATE       TO TI-TRR2-RESPONSE-DATE               
           MOVE  TI-TPSR-RESP-TIME       TO TI-TRR2-RESPONSE-TIME               
           COMPUTE WS-REINTENTO-TTIB = TI-CSEP-NUMERO-REINTENTOS        00160022
                                       + 1                              00160022
           MOVE  WS-REINTENTO-TTIB       TO TI-TRR2-NUMERO-REINTENTOS           
           MOVE  'L'                     TO TI-TRR2-TIPO-PROCESO                
           MOVE  '01'                    TO TI-TRR2-REENVIO                     
           PERFORM 2440-ENVIA-TRANSFERENCIA                                     
           .                                                            00069579
      *-----------------------*                                                 
       2599-VUELVE-A-LEER.                                                      
      *----------------------------------------------------------------*        
      * VUELVE A LEER EL REGISTRO DE PENDIENTES                      *          
      *----------------------------------------------------------------*        
      *                                                                         
      *MVP00103948-I                                                            
           MOVE 'N'     TO    WS-HUBO-ERROR                                     
      *MVP00103948-F                                                            
           EXEC  CICS READ  FILE   (WS-FILE-PENDREC)                            
                            UPDATE                                              
                            INTO   (TI-CSEP-REG-TRANS)                          
                            RIDFLD (WS-CLAVE-PEND)                              
                            LENGTH (LENGTH OF TI-CSEP-REG-TRANS)                
                         KEYLENGTH (LENGTH OF WS-CLAVE-PEND)                    
                            RESP   (WS-RESP)                                    
                            RESP2  (WS-RESP2)                                   
           END-EXEC                                                             
                                                                                
           EVALUATE WS-RESP                                                     
                WHEN  DFHRESP(NORMAL)                                           
                   CONTINUE                                                     
      *MVP00103948-I                                                            
      *         WHEN DFHRESP(ENDFILE)                                           
      *            MOVE  'S'   TO  WS-FIN-PEND                                  
      *MVP00103948-F                                                            
                WHEN DFHRESP(NOTFND)                                            
      *MVP00103948-I                                                            
      *            MOVE 'LEE ARCHIVO BCTIFSEP: NO EXISTE'                       
      *                                        TO WS-VARMSG-TXT                 
      *            SET WS-SI-EXISTE-ERROR      TO TRUE                          
      *            MOVE WS-FILE-PENDREC        TO WS-VARMSG-RSO                 
      *MVP00103948-F                                                            
                   MOVE 'S'                    TO WS-HUBO-ERROR                 
                WHEN OTHER                                                      
                   SET  WS-SI-EXISTE-ERROR     TO TRUE                          
                   MOVE 07                     TO WS-CODMSG-SEC                 
      *MVP00103948-I                                                            
      *            MOVE WS-FILE-PENDREC        TO WS-VARMSG-RSO                 
      *            MOVE 'S'                    TO WS-HUBO-ERROR                 
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
                   MOVE WS-RESP                TO WS-CSMT-COD-RETORNO           
                   MOVE WS-FILE-PENDREC        TO WS-CSMT-MENSAJE               
                   MOVE 'READ UPDATE'          TO WS-CSMT-MENSAJE(10:)          
                   PERFORM 3000-FINAL                                           
      *MVP00103948-F                                                            
           END-EVALUATE                                                         
           .                                                                    
      *--------------------*                                                    
      *                                                                         
      *-------------------------                                                
       2510-ACTUALIZA-PENDIENTES.                                               
      *----------------------------------------------------------------*        
      * ACTUALIZA ARCHIVO DE PENDIENTES                                *        
      *----------------------------------------------------------------*        
                                                                                
            IF  WS-HUBO-ERROR  EQUAL  'N'                                       
               COMPUTE WS-REINTENTO-TTIB = TI-CSEP-NUMERO-REINTENTOS    00160022
                                       + 1                              00160022
      *                                                                         
               MOVE  WS-REINTENTO-TTIB  TO  TI-CSEP-NUMERO-REINTENTOS   00160022
      *                                                                         
           EXEC CICS REWRITE FILE (WS-FILE-PENDREC)                     00160022
                             FROM (TI-CSEP-REG-TRANS)                           
                             RESP (WS-RESP)                                     
                            RESP2 (WS-RESP2)                                    
           END-EXEC                                                             
                                                                                
            IF WS-RESP EQUAL TO DFHRESP(NORMAL)                                 
               CONTINUE                                                         
            ELSE                                                                
              SET  WS-SI-ERROR-GRAL            TO TRUE                          
              SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                          
              MOVE 'REWRITE BCTIFSEP'          TO WS-CSMT-MENSAJE               
              MOVE WS-FILE-PENDREC             TO WS-VARMSG-RSO         00160022
              MOVE 07                          TO WS-CODMSG-SEC                 
              MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO           
              PERFORM 3000-FINAL                                                
             END-IF                                                             
            END-IF                                                              
           .                                                                    
      *----------------------------------------------------------------*        
       2521-LIBERA-F06.                                                         
      *----------------------------------------------------------------*        
      * LIBERA MAESTRO                                                *         
      *----------------------------------------------------------------*        
      *                                                                         
           EXEC CICS UNLOCK FILE (WS-FILE-NM-MAESTRO)                           
           RESP (WS-RESP)                                                       
           END-EXEC.                                                            
      *                                                                         
      *----------------------------------------------------------------*        
       2520-BORRA-PENDIENTES.                                                   
      *----------------------------------------------------------------*        
      * borra pendientes                                              *         
      *----------------------------------------------------------------*        
      *                                                                         
           EXEC CICS DELETE                                                     
                     FILE  (WS-FILE-PENDREC)                                    
                     RIDFLD(WS-CLAVE-PEND)                                      
                     KEYLENGTH(LENGTH OF WS-CLAVE-PEND)                         
                     RESP  (WS-RESP)                                            
                     RESP2 (WS-RESP2)                                           
           END-EXEC                                                             
                                                                                
           EVALUATE WS-RESP                                                     
                WHEN  DFHRESP(NORMAL)                                           
                   CONTINUE                                                     
                WHEN OTHER                                                      
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                     
      *MVP00103948-I                                                            
      *            MOVE 'REWRITE BCTIFSEP'          TO WS-CSMT-MENSAJE          
                   MOVE 'DELETE BCTIFSEP'           TO WS-CSMT-MENSAJE          
      *MVP00103948-F                                                            
                   MOVE 07                          TO WS-CODMSG-SEC            
                   MOVE WS-RESP                TO WS-CSMT-COD-RETORNO           
                   PERFORM 3000-FINAL                                           
           END-EVALUATE                                                         
                                                                                
           .                                                                    
      *------------------------*                                                
       2700-OBTIENE-MENSAJE-BCP.                                                
      *----------------------------------------------------------------*        
      * MUEVE DATOS PARA LA RUTINA DE ARMADO DE MENSAJES               *        
      *----------------------------------------------------------------*        
                                                                                
             MOVE SPACES                     TO TI-CA15-I-O-MENSAJES            
             MOVE 'TTIB'                     TO TI-CA15-I-RC-APP                
                                                                                
             MOVE WS-CODMSG-ESTRUCTURA       TO TI-CA15-I-RC-COD                
             MOVE WS-PROGRAM-ID              TO TI-CA15-I-VAR-PROGRAMA          
             MOVE WS-VARMSG-FUN              TO TI-CA15-I-VAR-FUNCION           
             MOVE WS-VARMSG-RSO              TO TI-CA15-I-VAR-RECURSO           
             MOVE WS-VARMSG-ARG              TO TI-CA15-I-VAR-ARGUMENTO         
             MOVE WS-VARMSG-TXT              TO TI-CA15-I-VAR-TEXTO             
             MOVE WS-RESP                    TO TI-CA15-I-EIBRESP               
             MOVE WS-RESP2                   TO TI-CA15-I-EIBRESP2              
             MOVE WS-RTN-MENSAJES            TO WS-RTN-SGTE                     
             MOVE TI-CA15-I-O-MENSAJES       TO WS-CCAA                         
             MOVE LENGTH OF TI-CA15-I-O-MENSAJES TO WS-LGTH-CCAA                
                                                                                
             EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                            
                              COMMAREA (WS-CCAA)                                
                                LENGTH (WS-LGTH-CCAA)                           
                                  RESP (WS-RESP)                                
                                 RESP2 (WS-RESP2)                               
             END-EXEC                                                           
                                                                                
             IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                            
                 SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                       
                 MOVE 05                         TO WS-CODMSG-SEC               
                 STRING 'BCTITPRA' 'RUTINA' WS-RTN-SGTE                         
                 'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO              
                 WS-CSMT-MENSAJE                                                
                 PERFORM 3000-FINAL                                             
             ELSE                                                               
                 MOVE WS-CCAA                    TO TI-CA15-I-O-MENSAJES        
                 MOVE TI-CA15-O-RCODE            TO WS-CODMSG-ESTRUCTURA        
                 MOVE TI-CA15-O-RC-MSG           TO WS-TXTMSG                   
             END-IF                                                             
             .                                                                  
      *----------------------------------------------------------------*        
       2800-OBTIENE-MENSAJE-CCE.                                                
      *----------------------------------------------------------------*        
      * MUEVE DATOS PARA LA RUTINA DE ARMADO DE MENSAJES               *        
      *----------------------------------------------------------------*        
                                                                                
             MOVE SPACES                     TO TI-CA15-I-O-MENSAJES            
             MOVE 'CCE'                      TO TI-CA15-I-RC-APP                
                                                                                
             MOVE WS-CODMSG-CCE              TO TI-CA15-I-RC-COD                
             MOVE WS-PROGRAM-ID              TO TI-CA15-I-VAR-PROGRAMA          
             MOVE WS-RESP                    TO TI-CA15-I-EIBRESP               
             MOVE WS-RESP2                   TO TI-CA15-I-EIBRESP2              
             MOVE WS-RTN-MENSAJES            TO WS-RTN-SGTE                     
             MOVE TI-CA15-I-O-MENSAJES       TO WS-CCAA                         
             MOVE LENGTH OF TI-CA15-I-O-MENSAJES TO WS-LGTH-CCAA                
                                                                                
             EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                            
                              COMMAREA (WS-CCAA)                                
                                LENGTH (WS-LGTH-CCAA)                           
                                  RESP (WS-RESP)                                
                                 RESP2 (WS-RESP2)                               
             END-EXEC                                                           
                                                                                
             IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                            
                 SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                       
                 MOVE 05                         TO WS-CODMSG-SEC               
                 STRING 'BCTITPRA' 'RUTINA' WS-RTN-SGTE                         
                 'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO              
                 WS-CSMT-MENSAJE                                                
                 PERFORM 3000-FINAL                                             
             ELSE                                                               
                 MOVE WS-CCAA                    TO TI-CA15-I-O-MENSAJES        
                 MOVE TI-CA15-O-RC-MSG           TO WS-MSG-CCE                  
             END-IF                                                             
             .                                                                  
                                                                                
      *----------------------------------------------------------------*        
       3000-FINAL.                                                              
      *----------------------------------------------------------------*        
      * FIN DEL PROCESO Y ENVIA MENSAJE AL OPERADOR                    *        
      *----------------------------------------------------------------*        
                                                                                
           IF WS-CODTIP-88-ERROR-RECURSOS                                       
              MOVE 'TTIB'      TO  WS-CSMT-COD-APLIC-04                         
              MOVE 'BCTITPRA'  TO  WS-CSMT-COD-PROGRAMA                         
              PERFORM 6000-WRITE-CSMT                                           
           END-IF                                                               
                                                                                
           PERFORM 7000-TERMINAR                                                
           .                                                                    
      *****************                                                         
       6000-WRITE-CSMT.                                                         
      *****************                                                         
      *************************************************************             
      * ESCRIBE EN LA CSMT.                                                     
      *************************************************************             
                                                                                
           EXEC CICS WRITEQ TD                                                  
                     QUEUE ('CSMT')                                             
                     FROM (WS-REG-GRABAR-CSMT)                                  
                     RESP (WS-RESP)                                             
                     RESP2 (WS-RESP2)                                           
           END-EXEC                                                             
           .                                                                    
      *************************************************************             
      * TERMINAR                                                                
      *************************************************************             
                                                                                
       7000-TERMINAR.                                                           
      *----------------------------------------------------------------*        
                                                                                
      *MVP00103948-I                                                            
           MOVE TI-CW04-DAT-TIME-INTERV-REI TO WS-INTERV-REI                    
      *MVP00103948-F                                                            
           EXEC CICS START                                                      
                TRANSID('TISP')                                                 
      *MVP00103948-I                                                            
      *         AFTER MINUTES(10)                                               
                AFTER MINUTES(WS-INTERV-REI)                                    
      *MVP00103948-F                                                            
                REQID('NONGL')                                                  
           END-EXEC                                                             
                                                                                
           EXEC CICS                                                            
                RETURN                                                          
           END-EXEC                                                             
           .                                                                    
      *-----------------------------------FIN DE 3000-TERMINAR-PROGRAMA*        
                                                                                
      *************************                                         00160022
       5500-OBTENER-TABLA-TTIB.                                         00160022
      *************************                                         00160022
      ******************************************************************00160022
      * CONSULTA NAMED COUNTER ESTADO DEL FLAG NEXT DAY TIN EN LINEA   *00160022
      ******************************************************************00160022
                                                                        00160022
           EXEC  CICS  LOAD                                                     
                    PROGRAM (WS-TSIS-TTIB)                                      
                        SET (WS-PTR-TSIS)                                       
                       RESP (WS-RESP)                                           
                      RESP2 (WS-RESP2)                                          
           END-EXEC                                                             
                                                                                
           IF  WS-RESP EQUAL DFHRESP(NORMAL)                                    
               SET  ADDRESS OF TI-CW04-REG-TABLA-SISTEMA                        
                                           TO WS-PTR-TSIS                       
           ELSE                                                                 
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                         
               MOVE 01                          TO WS-CODMSG-SEC                
               MOVE WS-TSIS-TTIB                TO WS-CSMT-MENSAJE              
               MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO          
               PERFORM 3000-FINAL                                               
           END-IF                                                               
           .                                                                    
      ************************ FIN DE 5500-OBTENER-TABLA-TTIB           00160022
      **************************                                        00160022
       5510-OBTENER-SESSION-ID.                                         00160022
      **************************                                        00160022
      ******************************************************************00160022
      * OBTIENE SESSION-ID                                             *00160022
      ******************************************************************00160022
                                                                        00160022
           MOVE TI-CW04-SYS-SESSION-ID     TO WS-NC-COUNTER-NAME        00160022
           MOVE 0                          TO WS-NRO-SESSION-ID         00160022
           EXEC  CICS  QUERY  COUNTER (WS-NC-COUNTER-NAME)              00160022
                                VALUE (WS-NRO-SESSION-ID)               00160022
                                 RESP (WS-RESP)                         00160022
                                RESP2 (WS-RESP2)                        00160022
           END-EXEC                                                     00160022
                                                                        00160022
           IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                              
                 OR WS-NRO-SESSION-ID EQUAL 0                                   
                 OR (WS-HORA-CORTE >= WS-CT-HORA-INI  AND                       
                     WS-HORA-CORTE <= WS-CT-HORA-FIN)                           
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                         
               MOVE 04                          TO WS-CODMSG-SEC                
               MOVE WS-NC-COUNTER-NAME          TO WS-CSMT-MENSAJE              
               MOVE WS-RESP                     TO WS-CSMT-COD-RETORNO          
               PERFORM 3000-FINAL                                               
           ELSE                                                         00160022
               MOVE WS-NRO-SESSION-ID         TO WS-NRO-SESSION-ID-ED           
               MOVE WS-NRO-SESSION-ID-ED      TO WS-NRO-SESSION-ID-TMP          
               UNSTRING WS-NRO-SESSION-ID-TMP DELIMITED BY ALL SPACES           
                  INTO WS-NRO-SESSION-ID-SPA,WS-NRO-SESSION-ID-TXT              
           END-IF                                                               
           .                                                                    
      **************************                                        00160022
       5600-OBTENER-ESTADO-TTIB.                                        00160022
      **************************                                        00160022
      ******************************************************************00160022
      * OBTIENE LA TABLA DE SISTEMA DE TIN EN LINEA                    *00160022
      ******************************************************************00160022
                                                                        00160022
           MOVE TI-CW04-SYS-NC-NEXT-DAY    TO WS-NC-COUNTER-NAME        00160022
           MOVE 0                          TO WS-NM-COUNTER-VALOR       00160022
           EXEC  CICS  QUERY  COUNTER (WS-NC-COUNTER-NAME)              00160022
                                VALUE (WS-NM-COUNTER-VALOR)             00160022
                                 RESP (WS-RESP)                         00160022
                                RESP2 (WS-RESP2)                        00160022
           END-EXEC                                                     00160022
                                                                        00160022
           EVALUATE WS-RESP                                             00160022
               WHEN DFHRESP(NORMAL)                                     00160022
                   MOVE WS-NM-COUNTER-VALOR TO WS-ESTADO-NEXT-DAY       00160022
                   MOVE WS-ESTADO-NEXT-DAY  TO WS-FLAG-NEXT-DAY         00160022
                   EVALUATE WS-ESTADO-NEXT-DAY                          00160022
                      WHEN 0 SET TI-CW04-88-CURRENT-DAY  TO TRUE        00160022
                      WHEN 7 SET TI-CW04-88-IN-PROCESS   TO TRUE        00160022
                      WHEN 9 SET TI-CW04-88-NEXT-DAY     TO TRUE        00160022
                      WHEN OTHER SET  WS-SI-EXISTE-ERROR TO TRUE        00160022
                   END-EVALUATE                                         00160022
                   IF  WS-SI-EXISTE-ERROR                               00160022
                       SET  WS-SI-EXISTE-ERROR TO TRUE                  00160022
                       SET  WS-CODTIP-88-ERROR-RECURSOS                 00160022
                                               TO TRUE                  00160022
                       MOVE 11                        TO WS-CODMSG-SEC  00160022
                       STRING 'COUNTER:' WS-NC-COUNTER-NAME                     
                       'VALOR NDAY INVALIDO' DELIMITED BY SIZE INTO             
                        WS-CSMT-MENSAJE                                         
                       PERFORM  3000-FINAL                              00160022
                   END-IF                                               00160022
               WHEN DFHRESP(INVREQ)                                     00160022
                   EVALUATE WS-RESP2                                    00160022
                       WHEN WS-RESP2-NOTFND                             00160022
                           SET  WS-SI-EXISTE-ERROR   TO TRUE            00160022
                           SET  WS-CODTIP-88-ERROR-RECURSOS             00160022
                                                     TO TRUE            00160022
                           MOVE 04                   TO WS-CODMSG-SEC   00160022
                           MOVE WS-RESP         TO WS-CSMT-COD-RETORNO  00160022
                           MOVE WS-NC-COUNTER-NAME   TO WS-CSMT-MENSAJE 00160022
                           PERFORM  3000-FINAL                          00160022
                       WHEN OTHER                                       00160022
                           SET  WS-SI-EXISTE-ERROR     TO TRUE          00160022
                   END-EVALUATE                                         00160022
               WHEN OTHER                                               00160022
                   SET  WS-SI-EXISTE-ERROR     TO TRUE                  00160022
           END-EVALUATE                                                 00160022
                                                                        00160022
           IF  WS-SI-EXISTE-ERROR                                       00160022
               SET  WS-SI-EXISTE-ERROR TO TRUE                          00160022
               SET  WS-CODTIP-88-ERROR-RECURSOS                         00160022
                                       TO TRUE                          00160022
               MOVE 11                 TO WS-CODMSG-SEC                 00160022
               MOVE WS-NC-COUNTER-NAME TO WS-CSMT-MENSAJE               00160022
               MOVE WS-RESP2           TO WS-CSMT-COD-RETORNO           00160022
               PERFORM  3000-FINAL                                      00160022
           END-IF                                                       00160022
           .                                                            00160022
      ************************                                          00160022
       7200-RUT-LINK-GRAL.                                                      
      *----------------------------------------------------------------*        
      * INVOCA CUALQUIER RUTINA VIA LINK, USANDO UNA COMMAREA COMUN    *        
      *----------------------------------------------------------------*        
                                                                                
           EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                              
                            COMMAREA (WS-CCAA)                                  
                              LENGTH (WS-LGTH-CCAA)                             
                                RESP (WS-RESP)                                  
                               RESP2 (WS-RESP2)                                 
           END-EXEC                                                             
                                                                                
           IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                              
               SET  WS-SI-ERROR-GRAL            TO TRUE                         
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                         
               MOVE 05                         TO WS-CODMSG-SEC                 
               MOVE WS-RESP                    TO WS-CSMT-COD-RETORNO           
               MOVE WS-RTN-SGTE                TO WS-CSMT-MENSAJE               
               PERFORM  3000-FINAL                                              
           END-IF                                                               
           .                                                                    
      ******************************************************************        
      *               R U T I N A S    G E N E R A L E S               *        
      ******************************************************************        
       9998-OBTIENE-ABEND.                                                      
      *----------------------------------------------------------------*        
      * OBTIENE EL CODIGO DEL ABEND GENERADO POR EL MODULO            *         
      *----------------------------------------------------------------*        
                                                                                
           EXEC  CICS                                                           
                                                                                
                 ASSIGN ABCODE (WS-ABCODE)                                      
                     ABPROGRAM (WS-ABPROGRAM)                                   
           END-EXEC                                                             
           .                                                                    
      *-----------------------*                                                 
       9999-MANEJO-EXCEPCIONES.                                                 
      *----------------------------------------------------------------*        
      * ACTUALIZAR ESTADO DE LA APLICACION CAMB A ACTIVO EN BCXRAV03   *        
      *----------------------------------------------------------------*        
                                                                                
           PERFORM  9998-OBTIENE-ABEND                                          
                                                                                
           SET  WS-SI-ERROR-GRAL           TO TRUE                              
           SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                             
           MOVE 17                         TO WS-CODMSG-SEC                     
           MOVE WS-ABCODE                  TO WS-CSMT-MENSAJE                   
           PERFORM 3000-FINAL                                                   
           .                                                                    
                                                                                
