       IDENTIFICATION DIVISION.                                         00010000
      *************************                                         00020000
                                                                        00030000
       PROGRAM-ID.    BCTITPR8.                                         00040000
       AUTHOR.        TCS-GUNS.                                         00050000
       INSTALLATION.  BANCO DE CREDITO.                                 00060000
       DATE-WRITTEN.  2021-MARZO.                                       00070000
      ******************************************************************00080000
      *                    PROPIEDAD DEL PROGRAMA                      *00090000
      *                                                                *00100000
      *   ESTE PROGRAMA Y SUS ELEMENTOS ASOCIADOS SON DE PROPIEDAD     *00110000
      *   DEL BANCO DE CREDITO DEL PERU Y NO PUEDE SER REPRODUCIDO,    *00120000
      *   DIVULGADO O UTILIZADO SIN UNA LICENCIA O AUTORIZACION        *00130000
      *   ESCRITA OTORGADA POR EL BANCO DE CREDITO DEL PERU.           *00140000
      *                                                                *00150000
      ******************************************************************00160000
      * SISTEMA   : TTIB  - TRANSFERENCIAS INTERBANCARIAS              *00170000
      *                                                                *00180000
      * MODULO    : TRANSFERENCIAS DE TTIB                             *00190000
      *                                                                *00200000
      * OBJETIVOS : RECEPTOR CONFIRMACION/CANCELACION 1                *00210000
      *                                                                *00220000
      *                                                                *00230000
      * FUNCIONES : 1. SE IMPLEMENTARA EL SERVICIO QUE SERÁ INVOCADO   *00240000
      *                POR VOCALINK              CUANDO EL BCP SEA     *00250000
      *                RECEPTOR                                        *00260000
      *                                                                *00270000
      *             2. GENERAR TRAMA DE CONSULTA A SYSTEMATICS O VISION*00280000
      *                PLUS                                            *00290000
      *                                                                *00300000
      *             3. VALIDAR QUE LA MONEDA SEA LA MISMA DE LA CUENTA *00310000
      *                DE ABONO                                        *00320000
      *                                                                *00330000
      *             4. VALIDAR SI LA CUENTA PERTENECE AL IDC DEL       *00340000
      *                BENEFICIARIO                                    *00350000
      *                                                                *00360000
      *             5. OBTENER MANCONUMOS DESDE CONSIST PARA CUENTAS   *00370000
      *                DE SYSTEMATICS. ESTO EN CASO EL IDC ENVIADO     *00380000
      *                NO COINCIDA                                     *00390000
      *                                                                *00400000
      * RUTINAS   :                                                    *00410000
      *                                                                *00420000
      *   BCNDAO05  RUTINA PARA VER EL ESTADO DE NEXT-DAY              *00430000
      ******************************************************************00440000
      *                                                                *00084358
      *              C O N T R O L   D E   C A M B I O S               *00084358
      ******************************************************************00084358
      * MODIFICACION  : VOCALINK (BASADO EN BCTITPR1)                  *00160022
      * FECHA         : 2022                                           *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : TA000184140                                    *00160022
      *----------------------------------------------------------------*00069579
      ******************************************************************        
      * MODIFICACION  : ADICION ENVIO DE NUEVOS CAMPOS                 *        
      * FECHA         : 15-03-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00127128                                    *        
      ******************************************************************        
      * MODIFICACION  : COMPLETA VALORES FALTANTES DE DATOS            *        
      * FECHA         : 30-05-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00139677                                    *        
      ******************************************************************        
      * MODIFICACION  : CORRIGE VALOR  TI-TRE2-CRITERIO-APLICACION     *        
      * FECHA         : 03-08-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00153165                                    *        
      ******************************************************************        
      *                                                                 00069579
      **********************                                            00450000
       ENVIRONMENT DIVISION.                                            00460000
      **********************                                            00470000
      ***************                                                   00480000
       DATA DIVISION.                                                   00490000
      ***************                                                   00500000
      *************************                                         00510000
       WORKING-STORAGE SECTION.                                         00520000
      *************************                                         00530000
                                                                        00540000
       01  WS-VARIABLES-GENERALES.                                      00550000
           05  WS-RBA-ESDS               PIC S9(08)  COMP.              00560000
      *GNS-I                                                                    
      *    05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR1'.  00570000
      *    05  WS-PROG-CONSULTA          PIC  X(08)  VALUE 'BCTITPR2'.  00580000
      *    05  WS-PROG-TRANSFERENCIA     PIC  X(08)  VALUE 'BCTITPR3'.  00581000
           05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR8'.  00570000
           05  WS-PROG-CONFIRMACION      PIC  X(08)  VALUE 'BCTITPR9'.  00581000
      *GNS-F                                                                    
           05  WS-PROGRAM-TP80           PIC  X(08)  VALUE 'BCTITP80'.  00590000
           05  WS-PROGRAM                PIC  X(08)  VALUE SPACES.      00591000
           05  WS-RTN-SGTE               PIC  X(08)  VALUE SPACES.      00600000
           05  WS-PROG-CALLER            PIC  X(08)  VALUE 'BCTITPE0'.  00610000
           05  WS-RTN-BCRGTP05           PIC  X(08)  VALUE 'BCRGTP05'.  00620000
           05  WS-RTN-BCIMTP27           PIC  X(08)  VALUE 'BCIMTP27'.  00630000
           05  WS-RTN-BCSTTP10           PIC  X(08)  VALUE 'BCSTTP10'.  00640000
           05  WS-RTN-SGCPPDGC           PIC  X(08)  VALUE 'SGCPPDGC'.  00650000
           05  WS-RTN-BCVPTP28           PIC  X(08)  VALUE 'BCVPTP28'.  00660000
           05  WS-RTN-BCRGTP04           PIC  X(08)  VALUE 'BCRGTP04'.  00670000
           05  WS-USUARIO                PIC  X(07)  VALUE '       '.   00680000
           05  WS-EYEID-ND               PIC  X(10)  VALUE 'NEXTDAYCOM'.00690000
           05  WS-APLID-SYST             PIC  X(04)  VALUE 'TTIB'.      00700000
           05  WS-PRG-NEXTDAY            PIC  X(08)  VALUE 'BCNDAO05'.  00710000
      *GNS-I                                                                    
      *    05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV03'.  00720000
           05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV04'.  00720000
      *GNS-F                                                                    
           05  WS-RTN-MENSAJES           PIC  X(08)  VALUE 'BCTITP15'.  00721000
           05  WS-ABSTIME-PROC           PIC S9(15) COMP-3 VALUE +0.    00730000
           05  WS-VALIDA-PRG1            PIC  9(01)  VALUE 0.           00740000
           05  WS-TMP-VC1                PIC  9(01)  VALUE 0.           00750000
           05  WS-TMP-CC1                PIC  X(30)  VALUE SPACES.      00760000
      *GNS-I                                                                    
      *    05  WS-TR02-MSGE-TYPE-ID      PIC  X(30)                     00770000
      *                                  VALUE 'TI-TR02-MSGE-TYPE-ID'.  00780000
      *    05  WS-TR02-COD-PROCESO       PIC  X(30)                     00790000
      *                                  VALUE 'TI-TR02-COD-PROCESO '.  00800000
      *    05  WS-I-TRAMA                PIC X(1600).                   00810000
      *GNS-F                                                                    
                                                                        00820000
           05  WS-LGTH-TEM               PIC S9(04) COMP VALUE 0.       00830000
           05  WS-PTR-TSIS-N             PIC S9(08) COMP VALUE 0.       00840000
           05  WS-PTR-TSIS-X   REDEFINES                                00850000
               WS-PTR-TSIS-N             PIC  X(04).                    00860000
           05  WS-PTR-TSIS     REDEFINES                                00870000
               WS-PTR-TSIS-N              USAGE IS POINTER.             00880000
           05  WS-BCOPZA.                                               00890000
               10 WS-CODREGI             PIC 9(02).                     00900000
               10 WS-BCODEST             PIC X(03).                     00910000
               10 WS-PZADEST             PIC X(03).                     00920000
           05  WS-LIMITE.                                               00930000
               10 WS-TIPPARM             PIC 9(02).                     00940000
               10 WS-TIPTRANS            PIC X(03).                     00950000
               10 WS-MONBCP              PIC X(04).                     00960000
               10 WS-TIPPZA              PIC X(01).                     00970000
               10 FILLER                 PIC X(20).                     00980000
           05 WS-FECHA-HORA-PROC.                                       00990000
               10 WS-FECHA-PROC          PIC 9(4).                      01000000
               10 WS-HORA-PROC           PIC 9(6).                      01010000
           05  WS-AREAID-I-CNL           PIC X(08).                     01020000
           05  WS-LGTH-I-OPE             PIC S9(04)  COMP VALUE 0.      01030000
           05  WS-LGTH-I-CNL             PIC S9(04)  COMP VALUE 0.      01040000
           05  WS-LGTH-O-CNL             PIC S9(04)  COMP VALUE 0.      01050000
           05  WS-PTR-I-CNL              USAGE IS POINTER.              01060000
           05  WS-PTR-I-CNL-X REDEFINES                                 01070000
               WS-PTR-I-CNL              PIC  X(04).                    01080000
           05  WS-PTR-I-CNL-N REDEFINES                                 01090000
               WS-PTR-I-CNL              PIC S9(08)  COMP.              01100000
                                                                        01110000
           05  WS-LGTH-CCAA              PIC S9(04) COMP VALUE 0.       01120000
           05  WS-CCAA                   PIC X(2000).                   01130000
                                                                        01140000
           05  WS-SYSID-LOC              PIC  X(04) VALUE SPACES.       01150000
           05  WS-ABCODE                 PIC  X(04) VALUE SPACES.       01160000
           05  WS-ABPROGRAM              PIC  X(08) VALUE SPACES.       01170000
                                                                        01180000
           05  WS-ABSTIME                PIC S9(15) COMP-3 VALUE +0.    01190000
           05  WS-FECHA-INI.                                            01200000
               10  WS-FEINI-CICS         PIC  9(08) VALUE 0.            01210000
               10  FILLER                PIC  X(02) VALUE SPACES.       01220000
           05  WS-HORA-INI.                                             01230000
               10  WS-HOINI-CICS         PIC  X(08) VALUE SPACES.       01240000
      *GNS-I                                                                    
           05  WS-RESPONSE-TIME.                                        01230000
               10  WS-RESPONSE-HOR       PIC  X(02) VALUE SPACES.       01240000
               10  WS-RESPONSE-MIN       PIC  X(02) VALUE SPACES.       01240000
               10  WS-RESPONSE-SEG       PIC  X(02) VALUE SPACES.       01240000
      *GNS-F                                                                    
           05  WS-NUM-SEGUNDOS           PIC S9(08) COMP  VALUE +1.     01250000
           05  WS-HORA-SS-INI            PIC 9(04) VALUE 0.             01260000
           05  WS-HORA-SS-FIN            PIC 9(04) VALUE 0.             01270000
           05  WS-HORA-SS-CNL            PIC 9(04) VALUE 0.             01280000
           05  WS-FECHA-FIN.                                            01290000
               10  WS-FEFIN-CICS         PIC  9(08) VALUE 0.            01300000
               10  FILLER                PIC  X(02) VALUE SPACES.       01310000
           05  WS-HORA-FIN.                                             01320000
               10  WS-HOFIN-CICS         PIC  X(08) VALUE SPACES.       01330000
           05  WS-TIEMPO-PROC            PIC  9(03) VALUE ZEROS.        01340000
                                                                        01350000
           05  WS-RECURSOS-CICS.                                        01360000
               10  WS-TIPO-CONEX             PIC  X(02) VALUE '  '.     01370000
                   88  WS-CONEX-LINK         VALUE  'D ' 'DS'.          01380000
                   88  WS-CONEX-START        VALUE  'S ' 'SD' 'SZ'.     01390000
                   88  WS-CONEX-TRIGGER      VALUE  'QD'.               01400000
                   88  WS-CONEX-SEND         VALUE  'TD'.               01410000
                   88  WS-CONEX-TASK         VALUE  'U '.               01420000
               10  WS-TRANID             PIC  X(04) VALUE SPACES.       01430000
               10  WS-CONVID             PIC  X(04) VALUE SPACES.       01440000
               10  WS-APPLID             PIC  X(08) VALUE SPACES.       01450000
                                                                        01460000
           05  WS-RESP                   PIC S9(08)  COMP VALUE +0.     01470000
           05  WS-RESP2                  PIC S9(08)  COMP VALUE +0.     01480000
           05  WS-RESP-TXT               PIC X(08)   VALUE SPACES.      01481000
           05  WS-CODIGO-RESP            PIC X(06).                     01490000
           05  WS-LONGITUD-RESP          PIC 9(05).                     01500000
           05  WS-IMPORTE                PIC X(20).                     01510000
           05  WS-IMPORTE-12             PIC X(12).                     01520000
           05  WS-IMPORTE-NV REDEFINES WS-IMPORTE-12   PIC 9(12).       01530000
           05  WS-MENSAJE-TXT            PIC  X(80)  VALUE SPACES.      01531000
           05  WS-MENSAJE-TXT-EVE        PIC  X(80)  VALUE SPACES.      01532000
      *GNS-I                                                                    
      *    05  WS-CT-NUMER               PIC 9(04)   VALUE ZEROS.       01533000
           05  WS-TEMP-XXXX              PIC X(04)   VALUE SPACES.      01533000
      *GNS-F                                                                    
           05  WS-TEMP-XX                PIC X(02)   VALUE SPACES.      01534000
           05  WS-COD-ERROR-07           PIC X(06)   VALUE '000000'.    01535000
           05  WS-CONTADOR-ENQ             PIC 9(02)   VALUE 1.         0008435 
           05  WS-CONTADOR-ENQ-MAX         PIC 9(02)   VALUE 15.        0008435 
      *GNS-I                                                                    
           05  WS-CREATION-DATE.                                        0008435 
               10  WS-YEAR-LOCAL             PIC 9(04)   VALUE ZEROS.   0008435 
               10  WS-DATE-LOCAL             PIC 9(04)   VALUE ZEROS.   0008435 
           05  WS-FECHA-LIQUIDACION.                                    0008435 
               10  WS-YEAR-LIQUIDACION       PIC 9(04)   VALUE ZEROS.   0008435 
               10  WS-FECHA-PROCE-CCE.                                  0008435 
                   15  WS-FECHA-PROCE-CCE-MM PIC 9(04)   VALUE ZEROS.       0008
                   15  WS-FECHA-PROCE-CCE-DD PIC 9(04)   VALUE ZEROS.       0008
           05  WS-DGC-GLS-NOMC-TMP.                                             
               10  WS-DGC-GLS-APAT-TMP       PIC X(25)   VALUE SPACES.          
               10  WS-DGC-GLS-AMAT-TMP       PIC X(25)   VALUE SPACES.          
               10  WS-DGC-GLS-NOMB-TMP       PIC X(25)   VALUE SPACES.          
      *GNS-F                                                                    
                                                                        0008435 
       01  WS-RESOURCE.                                                 0008435 
           05  WS-RESOURCE-BCP             PIC X(03)   VALUE 'BCP'.     0008435 
      *GNS-I                                                                    
      *    05  WS-RESOURCE-TX              PIC X(04)   VALUE 'TIRC'.    0008435 
           05  WS-RESOURCE-TX              PIC X(04)   VALUE 'TIRO'.    0008435 
      *GNS-F                                                                    
           05  WS-RESOURCE-KEY-TRANSF      PIC X(41)   VALUE SPACES.    0008435 
                                                                        01540000
       01  WS-FILE-NAME-TTIB.                                           00160022
           05  WS-FILE-NM-MAESTRO          PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT      PIC  X(08)  VALUE SPACES.    00160022
      *GNS-I                                                                    
      *    05  WS-FILE-NM-MAESTRO-ALT2     PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT3     PIC  X(08)  VALUE SPACES.    00160022
      *GNS-F                                                                    
           05  WS-FILE-NM-EVEN-LOG         PIC  X(08)  VALUE SPACES.    00160022
                                                                        00160022
       01  WS-REG-GRABAR-CSMT.                                          00160022
           05  WS-CSMT-COD-APLIC-04    PIC  X(04)      VALUE 'TTIB'.    00160022
           05  FILLER                  PIC  X(01)      VALUE SPACES.    00160022
      *GNS-I                                                                    
      *    05  WS-CSMT-COD-PROGRAMA    PIC  X(06)      VALUE SPACES.    00160022
           05  WS-CSMT-COD-PROGRAMA    PIC  X(08)      VALUE SPACES.    00160022
      *GNS-F                                                                    
           05  FILLER                  PIC  X(01)      VALUE SPACES.    00160022
           05  WS-CSMT-RESPUESTA.                                       00160022
               10  WS-CSMT-COD-RETORNO PIC  X(06)      VALUE SPACES.    00160022
               10  WS-CSMT-MENSAJE     PIC  X(80)      VALUE SPACES.    00160022
                                                                        01540000
       01  WS-CONSTANTES.                                               01550000
           05  WS-CT-TI                  PIC X(02) VALUE 'TI'.          01560000
           05  WS-CT-01                  PIC X(02) VALUE '01'.          01570000
           05  WS-CT-02                  PIC X(02) VALUE '02'.          01580000
           05  WS-CT-03                  PIC X(02) VALUE '03'.          01590000
           05  WS-CT-04                  PIC X(02) VALUE '04'.          01600000
           05  WS-CT-05                  PIC X(02) VALUE '05'.          01610000
           05  WS-CT-06                  PIC X(02) VALUE '06'.          01620000
           05  WS-CT-07                  PIC X(02) VALUE '07'.          01630000
           05  WS-CT-05C                 PIC X(03) VALUE '005'.         01640000
           05  WS-CT-10C                 PIC X(03) VALUE '010'.         01650000
           05  WS-CT-004                 PIC X(03) VALUE '004'.         01660000
           05  WS-CT-005                 PIC X(03) VALUE '005'.         01670000
           05  WS-CT-0200                PIC X(04) VALUE '0200'.        01680000
           05  WS-CT-0201                PIC X(04) VALUE '0201'.        01690000
           05  WS-CT-1006                PIC X(04) VALUE '1006'.        01690100
           05  WS-CT-1021                PIC X(04) VALUE '1021'.        01690200
           05  WS-CT-800000              PIC X(06) VALUE '800000'.      01700000
           05  WS-CT-490000              PIC X(06) VALUE '490000'.      01710000
           05  WS-CTN-0                  PIC 9(01) VALUE 0.             01720000
           05  WS-CTN-1                  PIC 9(01) VALUE 1.             01730000
      *    05  WS-CT-TI                  PIC X(02) VALUE 'TI'.          01740000
           05  WS-CT-L                   PIC X(01) VALUE 'L'.           01750000
           05  WS-CT-001                 PIC X(03) VALUE '001'.         01770000
           05  WS-CT-0210                PIC X(04) VALUE '0210'.        01780000
           05  WS-CT-00                  PIC X(02) VALUE '00'.          01790000
           05  WS-I                      PIC  9(04).                    01791000
           05  WS-ESTADO-NEXT-DAY        PIC  9(08) VALUE ZEROES.       00160022
      *GNS-I                                                                    
           05  WS-CT-325                 PIC X(03) VALUE '325'.                 
           05  WS-CT-DNOR                PIC X(04) VALUE 'DNOR'.        02410000
           05  WS-CT-FF02                PIC X(04) VALUE 'FF02'.        02410000
           05  WS-CT-ENTIDAD-ORIGEN      PIC  X(20)                     00810000
                                         VALUE 'ENTIDAD ORIGEN      '.  00820000
           05  WS-CT-ESTADO-ENT-ORI      PIC  X(20)                     00810000
                                         VALUE 'ESTADO ENTIDAD ORI  '.  00820000
           05  WS-CT-COD-PROCESO-CNF-CAN PIC  X(20)                     00810000
                                         VALUE 'COD PROCESO CNF CAN '.  00820000
           05  WS-CT-CCI-CLI-BENEFICIA   PIC  X(20)                     00810000
                                         VALUE 'CCI BEN             '.  00820000
           05  WS-CT-COD-TARJETA-CRED    PIC  X(20)                     00810000
                                         VALUE 'TJ CRED             '.  00820000
           05  WS-CT-IMPORTE             PIC  X(20)                     00810000
                                         VALUE 'IMPORTE             '.  00820000
           05  WS-CT-REF-INSTRUCTION-ID  PIC  X(20)                     00810000
                                         VALUE 'REF INSTRUCTION ID  '.  00820000
           05  WS-CT-INSTRUCTION-ID      PIC  X(20)                     00810000
                                         VALUE 'INSTRUCTION ID      '.  00820000
      *GNS-F                                                                    
                                                                        01800000
       01  WS-RPTA-MSG.                                                 01810000
           05  WS-CODMSG-ESTRUCTURA.                                    01820000
               10  WS-CODAPP             PIC  X(02)  VALUE 'TI'.        01830000
               10  WS-CODTIP             PIC  X(02).                    01840000
                   88  WS-CODTIP-88-CONFORME         VALUE '00'.        01850000
                   88  WS-CODTIP-88-ERROR-CONSIST    VALUE '04'.        01860000
                   88  WS-CODTIP-88-ERROR-RECURSOS   VALUE '08'.        01870000
                   88  WS-CODTIP-88-ERROR-AUTORIZ    VALUE '16'.        01880000
               10  WS-CODMSG            PIC  X(02).                     01890000
           05  WS-TXTMSG.                                               01900000
      *GNS-I                                                                    
      *        10 WS-ID-PROGRAM         PIC  X(08) VALUE 'BCTITPR1'.    01910000
               10 WS-ID-PROGRAM         PIC  X(08) VALUE 'BCTITPR8'.    01910000
      *GNS-F                                                                    
               10 FILLER                PIC  X(01) VALUE SPACES.        01920000
               10 WS-MENSAJE            PIC  X(71).                     01930000
      *GNS-I                                                                    
      *    05  WS-COD-PROG              PIC  X(08) VALUE 'BCTITPR1'.    01940000
           05  WS-COD-PROG              PIC  X(08) VALUE 'BCTITPR8'.    01940000
      *GNS-F                                                                    
                                                                        01950000
       01  WS-SWITCHES.                                                 01960000
                                                                        01970000
           05  WS-EXISTE-ERROR           PIC  X(01) VALUE 'N'.          01980000
               88  WS-NO-EXISTE-ERROR               VALUE 'N'.          01990000
               88  WS-SI-EXISTE-ERROR               VALUE 'S'.          02000000
               88  WS-SI-EXISTE-ERROR-G             VALUE 'G'.          02001000
                                                                        02010000
           05  WS-TRANSFER-ENCONTRADO    PIC  X(01) VALUE 'N'.          02020000
               88  WS-TRANSFER-ENCONTRADO-OK        VALUE 'N'.          02030000
               88  WS-TRANSFER-ENCONTRADO-NOOK      VALUE 'S'.          02040000
      *                                                                 02050000
           05  WS-RETRY-NDAY             PIC  9(02)  VALUE ZEROS.       02060000
           05  WS-RETRY-NDAY-MAX         PIC  9(02)  VALUE 05.          02070000
           05  WS-ESTADO-INTERFAZ        PIC  X(01)  VALUE 'I'.         02080000
           05  WS-ESTADO-ARCHIVOS        PIC  9(01)  VALUE 0.           02090000
               88  WS-ARCHIVOS-NODEF                 VALUE 0.           02100000
               88  WS-ARCHIVOS-LOCALES               VALUE 1.           02110000
               88  WS-ARCHIVOS-REMOTOS               VALUE 2.           02120000
               88  WS-ARCHIVOS-INOPERATIVOS          VALUE 3.           02130000
      *                                                                 02140000
           05  WS-FLAG-NEXT-DAY          PIC  9(01)  VALUE 0.           02150000
               88  WS-CURRENT-DAY                    VALUE 0.           02160000
               88  WS-IN-PROCESS                     VALUE 7.           02170000
               88  WS-NEXT-DAY                       VALUE 9.           02180000
      *                                                                 02190000
           05  WS-TRM-INPUT-ERROR       PIC  X(01)      VALUE SPACE .   02200000
               88  WS-TRM-INP-ERROR-NO VALUE 'N'.                       02210000
               88  WS-TRM-INP-ERROR-SI VALUE 'S'.                       02220000
      *                                                                 02230000
           05  WS-ERROR-BCKEND          PIC  X(01)      VALUE SPACE .   02240000
               88  WS-ERROR-BCKEND-SI  VALUE 'S'.                       02250000
               88  WS-ERROR-BCKEND-NO  VALUE 'N'.                       02260000
                                                                        02270000
           05  WS-TRAMA-INPUT            PIC  X(01)  VALUE 'N'.         02280000
               88  WS-TRAMAINP-OK                    VALUE 'N'.         02290000
               88  WS-TRAMAINP-NOOK                  VALUE 'S'.         02300000
                                                                        02310000
           05  WS-CANAL-ENCONTRADO       PIC  X(01)  VALUE 'N'.         02320000
               88  WS-CANAL-ENCONTRADO-OK            VALUE 'S'.         02330000
               88  WS-CANAL-ENCONTRADO-NOOK          VALUE 'N'.         02340000
                                                                        02350000
           05  WS-PARAMETRO-ENCONTRADO   PIC  X(01)  VALUE 'N'.         02360000
               88  WS-88-ENCONTRADO-OK               VALUE 'S'.         02370000
               88  WS-88-ENCONTRADO-NOOK             VALUE 'N'.         02380000
                                                                        02390000
           05  WS-LAST-RETRY             PIC  X(01)  VALUE 'N'.         02400000
               88  WS-NO-LAST-RETRY                  VALUE 'N'.         02410000
               88  WS-SI-LAST-RETRY                  VALUE 'S'.         02420000
                                                                        00084358
           05  WS-ENQ-RESOURCE             PIC  X(01)  VALUE 'N'.       00084358
               88  WS-ENQ-RESOURCE-NO                  VALUE 'N'.       00084358
               88  WS-ENQ-RESOURCE-SI                  VALUE 'S'.       00084358
                                                                        00084358
       01  WS-CONVERSIONES.                                             02430000
           05 WS-TI-TR02-IMPOR1       PIC  9(12).                       02440000
      *    05 WS-TI-TR02-IMPOR2       PIC  9(15).                       02450000
           05 WS-TR02-IMPORTE-R       REDEFINES WS-TI-TR02-IMPOR1       02460000
                                      PIC S9(10)V99.                    02470000
           05 WS-TI-TR02-IMPOR2       PIC  9(15).                       02480000
           05 WS-TR02-IMPORTE-COMI-R  REDEFINES WS-TI-TR02-IMPOR2       02490000
                                      PIC S9(13)V99.                    02500000
      *GNS-I                                                                    
           05 WS-TI-IMPORTE-E         PIC -9(14).9999.                          
      *GNS-F                                                                    
      *                                                                 02510000
       01  WS-CONTADORES-FILES.                                         02520000
           10 WS-NC-COUNTER-NAME       PIC  X(16) VALUE SPACES.         02530000
           10 WS-NRO-OPER-COUNTER      PIC S9(06) COMP  VALUE +0.       02540000
           10 WS-NRO-OPER-COUNTER-TMP  PIC S9(06) VALUE +0.             02550000
      *GNS-I                                                                    
           10 WS-REQ-ID-COUNTER        PIC S9(06) COMP  VALUE +0.       02540000
           10 WS-REQ-ID-COUNTER-TMP    PIC S9(06) VALUE +0.             02550000
      *GNS-F                                                                    
           10  WS-NM-COUNTER-VALOR     PIC S9(08)  COMP  VALUE +0.      00160022
                                                                        02560000
       01  WS-CODIGOS-ERRORES.                                          02570000
           05  WS-COD-E-OBT-CONEXION      PIC  X(02) VALUE '01'.        02580000
           05  WS-COD-E-OBT-SYSID         PIC  X(02) VALUE '02'.        02590000
           05  WS-COD-E-OBTIENE-FECHA     PIC  X(02) VALUE '03'.        02600000
           05  WS-COD-E-FORMATTIME        PIC  X(02) VALUE '04'.        02610000
           05  WS-COD-E-CARGA-TSIS        PIC  X(02) VALUE '05'.        02620000
           05  WS-COD-E-COMMAREA          PIC  X(02) VALUE '06'.        02630000
           05  WS-COD-E-CANAL-INV         PIC  X(02) VALUE '07'.        02640000
           05  WS-COD-E-TIP-PAGO          PIC  X(02) VALUE '08'.        02650000
           05  WS-COD-E-COD-MON           PIC  X(02) VALUE '09'.        02660000
           05  WS-COD-E-TIP-TRN           PIC  X(02) VALUE '10'.        02670000
           05  WS-COD-E-INTERNO-BCTITP8   PIC  X(02) VALUE '11'.        02680000
           05  WS-COD-E-GET-COUNTER       PIC  X(02) VALUE '12'.        02690000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(02) VALUE '13'.        02700000
           05  WS-COD-E-READ-UBIGEO       PIC  X(02) VALUE '14'.        02710000
           05  WS-COD-E-TRAMA-CONS        PIC  X(02) VALUE '15'.        02720000
           05  WS-COD-E-CONS-INCOR        PIC  X(02) VALUE '16'.        02730000
           05  WS-COD-E-TARIFA-NO-FOUND   PIC  X(02) VALUE '17'.        02740000
           05  WS-COD-E-RANGO-NO-FOUND    PIC  X(02) VALUE '18'.        02750000
           05  WS-COD-E-RANGO-MENOR       PIC  X(02) VALUE '19'.        02760000
           05  WS-COD-E-ACCESO-MAESTRO    PIC  X(02) VALUE '20'.        02770000
           05  WS-COD-E-DUP-RECORD        PIC  X(02) VALUE '21'.        02780000
           05  WS-COD-E-ARCHIVO-LOG       PIC  X(02) VALUE '22'.        02790000
           05  WS-COD-E-LINK-GRAL         PIC  X(02) VALUE '23'.        02800000
           05  WS-COD-E-NEXT-PROC         PIC  X(02) VALUE '24'.        02810000
           05  WS-COD-E-ASKTIME           PIC  X(02) VALUE '25'.        02820000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(02) VALUE '26'.        02830000
           05  WS-COD-E-INTERNO-BCTITP80  PIC  X(02) VALUE '27'.        02840000
           05  WS-COD-E-IMPORTE-SUP       PIC  X(02) VALUE '28'.        02850000
           05  WS-COD-E-LOG-EVENTOS       PIC  X(02) VALUE '29'.        02860000
           05  WS-COD-E-TRAMA-TRANS       PIC  X(02) VALUE '30'.        02870000
           05  WS-COD-E-FILE-PARAMETROS   PIC  X(02) VALUE '31'.        02880000
           05  WS-COD-E-ACCESS-FILE       PIC  X(02) VALUE '32'.        02890000
           05  WS-COD-E-CURRENT-DAY       PIC  X(02) VALUE '33'.        02900000
           05  WS-COD-E-NEXT-DAY          PIC  X(02) VALUE '34'.        02910000
           05  WS-COD-E-LINK-NEXT-DAY     PIC  X(02) VALUE '35'.        02920000
           05  WS-COD-E-TRAMA-OTRO        PIC  X(02) VALUE '36'.        02930000
           05  WS-COD-E-OBT-LINK          PIC  X(02) VALUE '37'.        02940000
           05  WS-COD-E-CARGAR-TABLA      PIC  X(02) VALUE '38'.        02950000
           05  WS-COD-E-NO-FOUND-PAR      PIC  X(02) VALUE '39'.        02960000
           05  WS-COD-E-LINK-BCTITP80     PIC  X(02) VALUE '36'.        02970000
                                                                        02980000
                                                                        02990000
       01  WS-DESCRIPCION-ERRORES.                                      03000000
           05  WS-88-ERROR-OBT-CONEXION  PIC  X(80) VALUE               03010000
               'ERROR EN ACCESO ARCHIVO LOG                     '.      03020000
           05  WS-88-ERROR-OBT-SYSID     PIC  X(80) VALUE               03030000
               'ERROR EN INVOKINGPROG                           '.      03040000
           05  WS-88-ERROR-OBTIENE-FECHA PIC  X(80) VALUE               03050000
               'ERROR AL RECUPERAR LA FECHA DEL SISTEMA         '.      03060000
           05  WS-88-ERROR-FORMATTIME    PIC  X(80) VALUE               03070000
               'ERROR EN FORMATTIME                             '.      03080000
           05  WS-88-ERROR-CARGA-TSIS    PIC  X(80) VALUE               03090000
               'ERROR AL CARGAR LA TABLA DEL SISTEMA            '.      03100000
           05  WS-88-ERROR-COMMAREA      PIC  X(80) VALUE               03110000
               'ERROR AL OBTENER CONEXION                       '.      03120000
           05  WS-88-ERROR-CANAL-INV     PIC  X(80) VALUE               03130000
               'ERROR AL RECIBIR LA TRAMA VIA LINK              '.      03140000
           05  WS-88-ERROR-TIP-PAGO      PIC  X(80) VALUE               03150000
               'ERROR AL RECIBIR LA TRAMA VIA START             '.      03160000
           05  WS-88-ERROR-COD-MON       PIC  X(80) VALUE               03170000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS             '.      03180000
           05  WS-88-ERROR-TIP-TRN       PIC  X(80) VALUE               03190000
               'NEXT DAY EN PROCESO                             '.      03200000
           05  WS-ERROR-INTERNO-BCTITP80 PIC  X(80) VALUE               03210000
               'NEXT DAY INICIO                                 '.      03220000
           05  WS-88-ERROR-ACTUALIZ      PIC  X(80) VALUE               03230000
               'ERROR AL OBTENER COUNTER                        '.      03240000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(80) VALUE              03250000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS       '.      03260000
           05  WS-88-ERROR-TRAMA-CONS    PIC  X(80) VALUE               03270000
               'ERROR AL RECIBIR LA TRAMA VIA LINK              '.      03280000
           05  WS-88-ERROR-CONS-INCOR    PIC  X(80) VALUE               03290000
               'ERROR AL RECIBIR LA TRAMA VIA START             '.      03300000
           05  WS-88-ERROR-RANGO-NO-FOUND PIC  X(80) VALUE              03310000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS             '.      03320000
           05  WS-88-ERROR-RANGO-MENOR   PIC  X(80) VALUE               03330000
               'NEXT DAY EN PROCESO                             '.      03340000
           05  WS-88-ERROR-ACCESO-MAESTRO PIC  X(80) VALUE              03350000
               'NEXT DAY INICIO                                 '.      03360000
           05  WS-88-ERROR-GET-COUNTER   PIC  X(80) VALUE               03370000
               'ERROR AL OBTENER COUNTER                        '.      03380000
           05  WS-88-ERROR-ARCHIVO-LOG    PIC  X(80) VALUE              03390000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS       '.      03400000
           05  WS-88-ERROR-LINK-GRAL      PIC  X(80) VALUE              03410000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS             '.      03420000
           05  WS-88-ERROR-NEXT-PROC     PIC  X(80) VALUE               03430000
               'NEXT DAY EN PROCESO                             '.      03440000
           05  WS-88-ERROR-ASKTIME        PIC  X(80) VALUE              03450000
               'NEXT DAY INICIO                                 '.      03460000
           05  WS-88-ERROR-REGISTRO-NO-FOUND PIC X(80) VALUE            03470000
               'ERROR AL OBTENER COUNTER                        '.      03480000
           05  WS-88-ERROR-READ-UBIGEO    PIC  X(80) VALUE              03490000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS       '.      03500000
           05  WS-88-ERROR-IMPORTE-SUP    PIC  X(80) VALUE              03510000
               'IMPORTE SUPERIOR                                '.      03520000
           05  WS-88-ERROR-GRABAR-LOGEVEN PIC  X(80) VALUE              03530000
               'ERROR AL GRABAR EN LOG DE EVENTOS               '.      03540000
           05  WS-88-ERROR-TRAMA-TRANS    PIC  X(80) VALUE              03550000
               'ERROR EN TRAMA DE TRANSFERENCIA                 '.      03560000
           05  WS-88-ERROR-FILE-PARAMETROS  PIC  X(80) VALUE            03570000
               'ERROR AL LEER ARCHIVO DE PARAMETROS             '.      03580000
           05  WS-88-ERROR-ACCESS-FILE      PIC X(80) VALUE             03590000
               'ERROR AL GRABAR EN MAESTRO DE TRANSACCIONES     '.      03600000
           05  WS-88-ERROR-CURRENT-DAY     PIC  X(70) VALUE             03610000
               'LA INTERFAZ TTIB SOLO FUNCIONA EN MODO CURRENT DAY '.   03620000
           05  WS-88-ERROR-NEXT-DAY      PIC  X(70) VALUE               03630000
               'EL MODO DE PROCESO (NEXT DAY), NO PUDO SER DETERMINADO'.03640000
           05  WS-88-ERROR-LINK-NEXT-DAY PIC  X(70) VALUE               03650000
               'ERROR AL ACCEDER AL PROGRAMA DE NEXT DAY              '.03660000
           05  WS-88-ERROR-TRAMA-OTRO    PIC  X(70) VALUE               03670000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03680000
           05  WS-88-ERROR-OBT-LINK      PIC  X(70) VALUE               03690000
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.03700000
           05  WS-88-ERROR-CARGAR-TABLA  PIC  X(70) VALUE               03710000
               'ERROR AL CARGAR LA TABLA DEL SISTEMA                  '.03720000
           05  WS-88-ERROR-NO-FOUND-PAR  PIC  X(70) VALUE               03730000
               'REGISTRO NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS    '.03740000
           05  WS-88-ERROR-LINK-BCTITP80 PIC  X(70) VALUE               03750000
               'ERROR AL HACER LINK AL PROGRAMA BCTITP80              '.03760000
      *                                                                 03770000
      *GNS-I                                                                    
      *01 WS-TMP-COMMAREA.                                              04500000
      *   05 WS-DFHAREA           PIC X(1700) VALUE SPACES.             04510000
      *GNS-F                                                                    
                                                                        04510100
       01  WS-VARIABLES-ERROR.                                          04511000
           05  WS-VARMSG-FUN             PIC  X(20)  VALUE SPACES.      04512000
           05  WS-VARMSG-RSO             PIC  X(20)  VALUE SPACES.      04513000
           05  WS-VARMSG-ARG             PIC  X(20)  VALUE SPACES.      04514000
           05  WS-VARMSG-TXT             PIC  X(30)  VALUE SPACES.      04515000
           05  WS-VARMSG-OPE             PIC  X(20)  VALUE SPACES.      04516000
      ******************************************************************04520000
      *                TABLA DE CODIGOS DE RESPUESTA                   *04530000
      ******************************************************************04540000
                                                                        04550000
       01  WS-COD-ORIG.                                                 04760000
           10  WS-COD-RESP              PIC X(04).                      04770000
           10  FILLER                   PIC X(01) VALUE SPACES.         04780000
           10  WS-ORI-RESP              PIC X(03).                      04790000
      *                                                                 04800000
      ******************************************************************04810000
      *                COPYBOOKS Y COMMAREAS DE TRABAJO                *04820000
      ******************************************************************04830000
                                                                        04840000
      *--------------  COPY TRAMA INPUT/OUTPUT NOVATRONICS              04850000
      *GNS-I                                                                    
      *COPY BCTITR02.                                                   04860000
       COPY BCTITRR2.                                                   04860000
      *GNS-F                                                                    
                                                                        04870000
      *--------------  COPY DE ARCHIVO LOG                              04880000
       COPY BCTICF07.                                                   04890000
                                                                        04900000
      *--------------  COMMAREA NEXT DAY                                04910000
       COPY BCNDYR90.                                                   04920000
                                                                        04930000
      *--------------  COPY DE ARCHIVO MAESTRO DE TRANSACCIONES         04940000
       COPY BCTICF06.                                                   04950000
                                                                        04960000
      *--------------  AREA DE COMUNICACION CON BCTITP80                04970000
       COPY BCTICA80.                                                   04980000
      *                                                                 04990000
      *--------------  COPY DE ARCHIVO DE PARAMETROS                    05000000
       COPY BCTICF01.                                                   05010000
      *                                                                 05020000
      *--------------  COMMAREA PARA PROGRAMAS DE RECEPTOR              00160022
      *GNS-I                                                                    
      *COPY BCTICA02.                                                   00160022
       COPY BCTICAR2.                                                   00160022
      *GNS-F                                                                    
                                                                        00160022
      *--------------  COMMAREA DE RUTINA MANEJO DE MENSAJES            05021000
       COPY BCTICA15.                                                   05022000
                                                                        05023000
      *--------------  COMMAREA DE RUTINA DE ACCESO A ARCHIVO DE PARAMET05030000
      *COPY BCTICA80.                                                   05040000
      *                                                                 05050000
      *****************                                                 05060000
       LINKAGE SECTION.                                                 05070000
      *****************                                                 05080000
      *GNS-I                                                                    
      *01  DFHCOMMAREA                 PIC  X(1540).                    05090000
       01  DFHCOMMAREA                 PIC  X(4000).                    05090000
      *GNS-F                                                                    
      *                                                                 05100000
      *--------------  TABLA DEL SISTEMA TTIB ONLINE                    05110000
      *GNS-I                                                                    
      *COPY BCTICW03.                                                   05120000
       COPY BCTICW04.                                                   05120000
      *GNS-F                                                                    
      *                                                                 05130000
      ********************                                              05140000
       PROCEDURE DIVISION.                                              05150000
      ********************                                              05160000
                                                                        05170000
           PERFORM  1000-INICIO                                         05180000
                                                                        05190000
      *GNS-I                                                                    
      *    IF  WS-NO-EXISTE-ERROR                                       05200000
      *        PERFORM  2000-PROCESO                                    05210000
      *    END-IF                                                       05220000
           PERFORM  2000-PROCESO                                        05210000
      *GNS-F                                                                    
                                                                        05230000
      *GNS-I                                                                    
      *    PERFORM  9000-TERMINAR.                                      05240000
           PERFORM  9000-TERMINAR                                       05240000
           .                                                                    
      *GNS-F                                                                    
                                                                        05250000
      ************************ FIN DE PROCEDURE DIVISION                05260000
      *************                                                     05261000
       1000-INICIO.                                                     05270000
      *************                                                     05271000
      ******************************************************************05280000
      * RECIBE COMMAREA                                                *05290000
      ******************************************************************05291000
                                                                        05310000
           EXEC  CICS                                                   05320000
               HANDLE ABEND                                             05330000
                      LABEL (9999-MANEJO-EXCEPCIONES)                   05340000
           END-EXEC                                                     05350000
      *                                                                 05360000
                                                                        05361000
           INITIALIZE  TI-CF06-REG-TRANS                                05362000
                       REPLACING  ALPHANUMERIC DATA BY SPACES           05363000
                                       NUMERIC DATA BY ZEROS            05364000
                                                                        05365000
      *GNS-I                                                                    
      *    PERFORM  1100-OBTIENE-SYSID                                  05370000
      *GNS-F                                                                    
           PERFORM  1200-OBTIENE-FECHA-HORA-INICIO                      05380000
           PERFORM  1300-RECIBE-COMMAREA                                05390000
           PERFORM  1400-CARGA-TABLA-SIST-TTIB                          05400000
           PERFORM  1500-CARGAR-VARIBLES-CD-ND                          00160022
      *GNS-I                                                                    
      *    PERFORM  1600-VERIFICAR-TRAMA                                00160022
      *GNS-F                                                                    
      *    PERFORM  1600-OBTIENE-NEXT-DAY                               00160022
           .                                                            05430000
      ************************ FIN DE 1000-INICIO                       05431000
      *GNS-I                                                                    
      ********************                                              05432000
      *1100-OBTIENE-SYSID.                                              05440000
      ********************                                              05441000
      ******************************************************************05442000
      * OBTIENE EL SYSID DEL CICS DONDE SE EJECUTA EL PROGRAMA         *05460000
      ******************************************************************05461000
      *                                                                 05480000
      *    EXEC  CICS  ASSIGN                                           05490000
      *          INVOKINGPROG (WS-PROG-CALLER)                          05500000
      *             STARTCODE (WS-TIPO-CONEX)                           05510000
      *                 SYSID (WS-SYSID-LOC)                            05520000
      *                USERID (WS-USUARIO)                              05530000
      *                  RESP (WS-RESP)                                 05540000
      *                 RESP2 (WS-RESP2)                                05550000
      *    END-EXEC                                                     05560000
      *                                                                 05570000
      *    IF  WS-RESP  NOT EQUAL DFHRESP(NORMAL)                       05580000
      *        SET  WS-SI-EXISTE-ERROR          TO TRUE                 05590000
      *        SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 05600000
      *        MOVE WS-COD-E-OBT-SYSID          TO WS-CODMSG            05610000
      *        MOVE WS-88-ERROR-OBT-SYSID       TO WS-MENSAJE           05620000
      *        PERFORM  6000-FINAL                                      05630000
      *    END-IF                                                       05640000
      *    .                                                            05641000
      ************************ FIN DE 1100-OBTIENE-SYSID                05650000
      *GNS-F                                                                    
      ********************************                                  05651000
       1200-OBTIENE-FECHA-HORA-INICIO.                                  05660000
      ********************************                                  05661000
      ******************************************************************05662000
      * RECUPERAMOS LA FECHA Y HORA DE INICIO  DESDE EL CICS.          *05680000
      ******************************************************************05681000
                                                                        05700000
           EXEC  CICS  ASKTIME                                          05710000
                       ABSTIME (WS-ABSTIME)                             05720000
                          RESP (WS-RESP)                                05730000
                         RESP2 (WS-RESP2)                               05740000
           END-EXEC                                                     05750000
      *                                                                 05760000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        05770000
      *GNS-I                                                                    
      *        SET  WS-SI-EXISTE-ERROR          TO TRUE                 05780000
      *GNS-F                                                                    
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 05790000
               MOVE WS-COD-E-OBTIENE-FECHA      TO WS-CODMSG            05800000
               MOVE WS-88-ERROR-OBTIENE-FECHA   TO WS-MENSAJE           05810000
      *GNS-I                                                                    
               MOVE WS-CODMSG-ESTRUCTURA        TO WS-CSMT-COD-RETORNO  05800000
               MOVE WS-COD-PROG                 TO WS-CSMT-COD-PROGRAMA 05800000
               MOVE WS-TXTMSG                   TO WS-CSMT-MENSAJE      05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
      *GNS-F                                                                    
               PERFORM 6000-FINAL                                       05820000
           END-IF                                                       05830000
                                                                        05840000
           EXEC  CICS  FORMATTIME                                       05850000
                          ABSTIME (WS-ABSTIME)                          05860000
                         YYYYMMDD (WS-FECHA-INI)                        05870000
                             TIME (WS-HORA-INI)                         05880000
                          TIMESEP                                       05890000
                             RESP (WS-RESP)                             05900000
                            RESP2 (WS-RESP2)                            05910000
           END-EXEC                                                     05920000
                                                                        05930000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        05940000
      *GNS-I                                                                    
      *        SET  WS-SI-EXISTE-ERROR          TO TRUE                 05950000
      *GNS-F                                                                    
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 05960000
               MOVE WS-COD-E-FORMATTIME         TO WS-CODMSG            05970000
               MOVE WS-88-ERROR-FORMATTIME      TO WS-MENSAJE           05980000
      *GNS-I                                                                    
               MOVE WS-CODMSG-ESTRUCTURA        TO WS-CSMT-COD-RETORNO  05800000
               MOVE WS-COD-PROG                 TO WS-CSMT-COD-PROGRAMA 05800000
               MOVE WS-TXTMSG                   TO WS-CSMT-MENSAJE      05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
      *GNS-F                                                                    
              PERFORM 6000-FINAL                                        05990000
           END-IF                                                       06000000
           .                                                            06000100
      ************************ FIN DE 1200-OBTIENE-FECHA-HORA-INICIO    06001000
      **********************                                            06010000
       1300-RECIBE-COMMAREA.                                            06020000
      **********************                                            06021000
      ******************************************************************06022000
      * IDENTIFICA A PARTIR DE LOS RECURSOS CICS EL TIPO DE LLAMADA A  *06040000
      * NUESTRO PROGRAMA Y RECIBE LA TRAMA DE ENTRADA.                 *06050000
      ******************************************************************06051000
      *GNS-I                                                                    
      *                                                                 06070000
      *    SET WS-NO-EXISTE-ERROR               TO TRUE                 06080000
      *    IF  WS-NO-EXISTE-ERROR THEN                                  06090000
      *        PERFORM  1310-OBTIENE-TRAMA-IN                           06100000
      *    END-IF                                                       06110000
      *    .                                                            06110100
      ************************ FIN DE 1300-RECIBE-COMMAREA              06111000
      ***********************                                           06112000
      *1310-OBTIENE-TRAMA-IN.                                           06130000
      ***********************                                           06131000
      ******************************************************************06132000
      * DEPENDE DE LA CONEX SE RECIBE LA COMMAREA DE DATOS             *06150000
      ******************************************************************06151000
      *                                                                 06170000
      *    IF  EIBCALEN  GREATER THAN  ZEROS                            06180000
      *        SET WS-CONEX-LINK TO TRUE                                06190000
      *    END-IF                                                       06200000
      **                                                                06210000
      *    EVALUATE  TRUE                                               06220000
      *       WHEN  WS-CONEX-LINK                                       06230000
      *             PERFORM  1320-RECIBE-TRAMA-LINK                     06240000
      *       WHEN  OTHER                                               06250000
      *             CONTINUE                                            06251000
      *    END-EVALUATE                                                 06280000
      *    .                                                            06281000
      ************************ FIN DE 1310-OBTIENE-TRAMA-IN             06282000
      ************************                                          06283000
      *1320-RECIBE-TRAMA-LINK.                                          06300000
      ************************                                          06300100
      ******************************************************************06301000
      * DIRECCIONA LA COMMAREA DE LA TRAMA DE ENTRADA RECIBIDA VIA LINK*06320000
      ******************************************************************06321000
      *GNS-F                                                                    
                                                                        06340000
           IF  EIBCALEN  GREATER  0                                     06350000
      *GNS-I                                                                    
      *        MOVE DFHCOMMAREA                 TO TI-TR02-I-TRAMA      06360000
               MOVE DFHCOMMAREA                 TO TI-TRR2-I-TRAMA      06360000
      *GNS-F                                                                    
           ELSE                                                         06370000
      *GNS-I                                                                    
      *        SET  WS-SI-EXISTE-ERROR          TO TRUE                 06380000
      *GNS-F                                                                    
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 06390000
               MOVE WS-COD-E-OBT-LINK           TO WS-CODMSG            06400000
               MOVE WS-88-ERROR-OBT-LINK        TO WS-MENSAJE           06410000
      *GNS-I                                                                    
               MOVE WS-CODMSG-ESTRUCTURA        TO WS-CSMT-COD-RETORNO  05800000
               MOVE WS-COD-PROG                 TO WS-CSMT-COD-PROGRAMA 05800000
               MOVE WS-TXTMSG                   TO WS-CSMT-MENSAJE      05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
      *GNS-F                                                                    
               PERFORM 6000-FINAL                                       06420000
           END-IF                                                       06430000
      *                                                                         
      *GNS-I                                                                    
           MOVE TI-TRR2-RESPONSE-CODE-CCE TO TI-CAR2-COD-PROCESO-CNF-CAN05390000
           MOVE SPACES                    TO TI-TRR2-RESPONSE-CODE-CCE  05390000
           IF TI-CAR2-88-COD-PROCESO-CAN                                        
               MOVE WS-FECHA-INI          TO TI-TRR2-RESPONSE-DATE          0672
               MOVE WS-HORA-INI(1:2)      TO WS-RESPONSE-HOR                0672
               MOVE WS-HORA-INI(4:2)      TO WS-RESPONSE-MIN                0672
               MOVE WS-HORA-INI(7:2)      TO WS-RESPONSE-SEG                0672
               MOVE WS-RESPONSE-TIME      TO TI-TRR2-RESPONSE-TIME          0672
           END-IF                                                               
      *GNS-F                                                                    
           .                                                            06431000
      ************************ FIN DE 1320-RECIBE-TRAMA-LINK            06432000
      ****************************                                      06433000
       1400-CARGA-TABLA-SIST-TTIB.                                      06434000
      ****************************                                      06435000
      ******************************************************************06436000
      * OBTIENE EL SYSID DE LA REGION CICS DONDE SE EJECUTA EL PRGM. Y *06437000
      * CARGA  LA TABLA DEL SYSTEMA TTIB                               *06438000
      ******************************************************************06439000
                                                                        06439100
           EXEC  CICS  LOAD                                             06439200
                    PROGRAM (WS-TSIS-TTIB)                              06439300
                        SET (WS-PTR-TSIS)                               06439400
                       RESP (WS-RESP)                                   06439500
                      RESP2 (WS-RESP2)                                  06439600
           END-EXEC                                                     06439700
                                                                        06439800
           IF  WS-RESP EQUAL DFHRESP(NORMAL)                            06439900
      *GNS-I                                                                    
      *        SET  ADDRESS OF TI-CW03-REG-TABLA-SISTEMA                06440000
               SET  ADDRESS OF TI-CW04-REG-TABLA-SISTEMA                06440000
      *GNS-F                                                                    
                                           TO WS-PTR-TSIS               06440100
           ELSE                                                         06440500
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *        OBTENER MENSAJE PARA CCE                                 06440700
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06440800
      *                                                                 06440900
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      06441000
      *        SET  TI-CF06-88-RECH        TO TRUE                      06441100
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     06441200
                                          WS-TEMP-XX                    06441300
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    06441400
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     06441500
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    06441600
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   06441700
                                          WS-TEMP-XXXX                  06441700
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      06441800
      *GNS-I                                                                    
      *        PERFORM 6100-OBTENER-MENSAJE                             06441900
      *                                                                 06442000
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     06442100
      *GNS-F                                                                    
               PERFORM 6300-ACTUALIZA-COMAREA                           06442200
                                                                        06442300
      *        OBTENER MENSAJE INTERNO                                  06442400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06442500
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      06442600
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    06442700
                                              WS-CODMSG-ESTRUCTURA      06442800
                                              WS-COD-ERROR-07           06442900
                                              WS-CSMT-COD-RETORNO       00160022
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            06443000
                                              WS-CSMT-COD-PROGRAMA      00160022
               MOVE 'LOAD'                 TO WS-VARMSG-FUN             06443100
               MOVE WS-TSIS-TTIB           TO WS-VARMSG-RSO             06443200
                                                                        06443300
               PERFORM 6100-OBTENER-MENSAJE                             06443400
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            06443500
                                              WS-CSMT-MENSAJE           00160022
                                                                        06443600
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          00160022
               PERFORM 6400-WRITE-CSMT                                  00160022
               PERFORM 6000-FINAL                                       06443900
           END-IF                                                       06444000
           .                                                            06444100
      ************************ FIN DE 1400-CARGA-TABLA-SIST-TTIB        06445000
      ****************************                                      00160022
       1500-CARGAR-VARIBLES-CD-ND.                                      00160022
      ****************************                                      00160022
                                                                        00160022
           PERFORM 1520-OBTENER-ESTADO-CD-ND                            00160022
      *GNS-I                                                                    
      *    MOVE TI-CW03-FLAG-NEXT-DAY      TO WS-FLAG-NEXT-DAY          00160022
      *                                                                 00160022
      *    IF  TI-CW03-88-CURRENT-DAY                                   00160022
      *        OR  TI-CW03-88-NEXT-DAY                                  00160022
      *        EVALUATE  TRUE                                           00160022
      *            WHEN WS-CURRENT-DAY                                  00160022
      *                MOVE TI-CW03-FILE-MAESTRO                        00160022
      *                                    TO WS-FILE-NM-MAESTRO        00160022
      *                MOVE TI-CW03-FILE-MAESTRO-ALT                    00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT    00160022
      *                MOVE TI-CW03-FILE-MAESTRO-ALT2                   00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT2   00160022
      *                MOVE TI-CW03-FILE-EVEN-LOG                       00160022
      *                                    TO WS-FILE-NM-EVEN-LOG       00160022
           MOVE TI-CW04-FLAG-NEXT-DAY      TO WS-FLAG-NEXT-DAY          00160022
                                                                        00160022
           IF  TI-CW04-88-CURRENT-DAY                                   00160022
               OR  TI-CW04-88-NEXT-DAY                                  00160022
               EVALUATE  TRUE                                           00160022
                   WHEN WS-CURRENT-DAY                                  00160022
                       MOVE TI-CW04-FILE-MAESTRO                        00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT                    00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT3                   00160022
                                           TO WS-FILE-NM-MAESTRO-ALT3   00160022
                       MOVE TI-CW04-FILE-EVEN-LOG                       00160022
                                           TO WS-FILE-NM-EVEN-LOG       00160022
      *GNS-F                                                                    
                                                                        00160022
                   WHEN WS-NEXT-DAY                                     00160022
      *GNS-I                                                                    
      *                MOVE TI-CW03-FILE-MAESTRO-NDAY                   00160022
      *                                    TO WS-FILE-NM-MAESTRO        00160022
      *                MOVE TI-CW03-FILE-MAESTRO-ALT-NDAY               00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT    00160022
      *                MOVE TI-CW03-FILE-MAESTRO-AL2-NDAY               00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT2   00160022
      *                MOVE TI-CW03-FILE-EVEN-LOG-NDAY                  00160022
      *                                    TO WS-FILE-NM-EVEN-LOG       00160022
                       MOVE TI-CW04-FILE-MAESTRO-NDAY                   00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
                       MOVE TI-CW04-FILE-MAESTRO-ALT-NDAY               00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
                       MOVE TI-CW04-FILE-MAESTRO-AL3-NDAY               00160022
                                           TO WS-FILE-NM-MAESTRO-ALT3   00160022
                       MOVE TI-CW04-FILE-EVEN-LOG-NDAY                  00160022
                                           TO WS-FILE-NM-EVEN-LOG       00160022
      *GNS-F                                                                    
                                                                        00160022
               END-EVALUATE                                             00160022
                                                                        00160022
           ELSE                                                                 
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *    OBTENER MENSAJE PARA CCE                                     00160022
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      00160022
      *                                                                 00160022
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      00160022
      *        SET  TI-CF06-88-RECH        TO TRUE                      00160022
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 00160022
                                              WS-TEMP-XX                00160022
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)00160022
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)00160022
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               00160022
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  00160022
      *GNS-I                                                                    
      *        PERFORM 6100-OBTENER-MENSAJE                             00160022
      *                                                                 00160022
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 00160022
      *GNS-F                                                                    
               PERFORM 6300-ACTUALIZA-COMAREA                           00160022
                                                                        00160022
      *    OBTENER MENSAJE INTERNO                                              
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      00160022
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      00160022
               MOVE 'TI0415'               TO TI-CF06-CODMSG-ESTRUCT    00160022
                                              WS-CODMSG-ESTRUCTURA      00160022
                                              WS-COD-ERROR-07           00160022
                                              WS-CSMT-COD-RETORNO       00160022
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            00160022
                                              WS-PROGRAM                00160022
                                              WS-CSMT-COD-PROGRAMA      00160022
               PERFORM 6100-OBTENER-MENSAJE                             00160022
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            00160022
                                              WS-CSMT-MENSAJE           00160022
                                                                        00160022
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          00160022
               PERFORM 6400-WRITE-CSMT                                  00160022
               PERFORM 6000-FINAL                                       00160022
                                                                        00160022
           END-IF                                                               
           .                                                            00160022
      ************************ FIN DE 1500-CARGAR-VARIBLES-CD-ND        00160022
      ***************************                                       00160022
       1520-OBTENER-ESTADO-CD-ND.                                       00160022
      ***************************                                       00160022
                                                                        00160022
      *GNS-I                                                                    
      *    MOVE TI-CW03-SYS-NC-NEXT-DAY    TO WS-NC-COUNTER-NAME        00160022
           MOVE TI-CW04-SYS-NC-NEXT-DAY    TO WS-NC-COUNTER-NAME        00160022
      *GNS-F                                                                    
           MOVE 0                          TO WS-NM-COUNTER-VALOR       00160022
                                                                        00160022
           EXEC CICS QUERY                                              00160022
                 COUNTER (WS-NC-COUNTER-NAME)                           00160022
                   VALUE (WS-NM-COUNTER-VALOR)                          00160022
                    RESP (WS-RESP)                                      00160022
                   RESP2 (WS-RESP2)                                     00160022
           END-EXEC                                                     00160022
                                                                        00160022
           IF  WS-RESP  EQUAL  DFHRESP(NORMAL)                          00160022
               MOVE WS-NM-COUNTER-VALOR    TO WS-ESTADO-NEXT-DAY        00160022
               EVALUATE WS-ESTADO-NEXT-DAY                              00160022
      *GNS-I                                                                    
      *            WHEN 0 SET TI-CW03-88-CURRENT-DAY  TO TRUE           00160022
      *            WHEN 7 SET TI-CW03-88-IN-PROCESS   TO TRUE           00160022
      *            WHEN 9 SET TI-CW03-88-NEXT-DAY     TO TRUE           00160022
                   WHEN 0 SET TI-CW04-88-CURRENT-DAY  TO TRUE           00160022
                   WHEN 7 SET TI-CW04-88-IN-PROCESS   TO TRUE           00160022
                   WHEN 9 SET TI-CW04-88-NEXT-DAY     TO TRUE           00160022
      *GNS-F                                                                    
                   WHEN OTHER                                           00160022
                       PERFORM 1620-ACTUALIZA-COMAREA                   00160022
      *            OBTENER MENSAJE PARA CCE                             00160022
      *GNS-I                                                                    
      *                MOVE SPACES             TO TI-CA15-I-O-MENSAJES  00160022
      *                                                                 00160022
      *                SET  TI-CA15-I-RC-APP-CCE   TO TRUE              00160022
      *                SET  TI-CF06-88-RECH        TO TRUE              00160022
      *GNS-F                                                                    
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 00160022
                                              WS-TEMP-XX                00160022
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)00160022
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)00160022
      *                MOVE WS-CT-1021     TO WS-CT-NUMER               00160022
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  00160022
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *                PERFORM 6100-OBTENER-MENSAJE                     00160022
      *                                                                 00160022
      *                MOVE WS-MENSAJE-TXT                              00160022
      *                                    TO TI-CF06-MENSAJE-RESPUESTA 00160022
      *GNS-F                                                                    
                       PERFORM 6300-ACTUALIZA-COMAREA                   00160022
                                                                        00160022
      *            OBTENER MENSAJE INTERNO                              00160022
                       MOVE SPACES         TO TI-CA15-I-O-MENSAJES      00160022
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE              00160022
                       MOVE 'TI0804'       TO TI-CF06-CODMSG-ESTRUCT    00160022
                                              WS-CODMSG-ESTRUCTURA      00160022
                                              WS-COD-ERROR-07           00160022
                       MOVE WS-PROGRAM-ID  TO TI-CF06-PRGNOM            00160022
                                              WS-PROGRAM                00160022
                       MOVE WS-NC-COUNTER-NAME     TO WS-VARMSG-RSO     00160022
                                                                        00160022
                       PERFORM 6100-OBTENER-MENSAJE                     00160022
                       MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG    00160022
      *GNS-I                                                                    
                                                      WS-MENSAJE-TXT-EVE00160022
      *GNS-F                                                                    
                                                                        00160022
                       PERFORM 6200-GRABAR-LOG-EVENTOS                  00160022
                       PERFORM 6000-FINAL                               00160022
                                                                        00160022
               END-EVALUATE                                             00160022
                                                                        00160022
           ELSE                                                         00160022
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *        OBTENER MENSAJE PARA CCE                                 00160022
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      00160022
      *                                                                 00160022
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      00160022
      *        SET  TI-CF06-88-RECH        TO TRUE                      00160022
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     00160022
                                          WS-TEMP-XX                    00160022
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    00160022
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     00160022
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    00160022
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   00160022
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                                          WS-TEMP-XXXX                  00160022
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      00160022
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             00160022
      *                                                                 00160022
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     00160022
      *GNS-F                                                                    
               PERFORM 6300-ACTUALIZA-COMAREA                           00160022
                                                                        00160022
      *        OBTENER MENSAJE INTERNO                                  00160022
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      00160022
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      00160022
               MOVE 'TI0804'               TO TI-CF06-CODMSG-ESTRUCT    00160022
                                              WS-CODMSG-ESTRUCTURA      00160022
                                              WS-COD-ERROR-07           00160022
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            00160022
                                              WS-PROGRAM                00160022
               MOVE WS-NC-COUNTER-NAME     TO WS-VARMSG-RSO             00160022
                                                                        00160022
               PERFORM 6100-OBTENER-MENSAJE                             00160022
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            00160022
      *GNS-I                                                                    
                                              WS-MENSAJE-TXT-EVE        00160022
      *GNS-F                                                                    
                                                                        00160022
                                                                        06443700
               PERFORM 6200-GRABAR-LOG-EVENTOS                          06443800
               PERFORM 6000-FINAL                                       06443900
           END-IF                                                       06444000
           .                                                            06444100
      ************************ FIN DE 1520-OBTENER-ESTADO-CD-ND         00160022
      *GNS-I                                                                    
      **********************                                            06491000
      *1600-VERIFICAR-TRAMA.                                            00160022
      **********************                                            06501000
      **                                                                06520000
      *                                                                 06522000
      *    IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0200 AND                    06530000
      *        TI-TR02-COD-PROCESO  = WS-CT-800000                      06540000
      *        CONTINUE                                                 06550000
      *    ELSE                                                         06560000
      *        IF  (TI-TR02-MSGE-TYPE-ID = WS-CT-0200  OR               06570000
      *            TI-TR02-MSGE-TYPE-ID = WS-CT-0201) AND               06580000
      *            TI-TR02-COD-PROCESO  = WS-CT-490000                  06590000
      *            CONTINUE                                             06600000
      *        ELSE                                                     06610000
      *            PERFORM 1620-ACTUALIZA-COMAREA                       00160022
      **           OBTENER MENSAJE PARA CCE                             06640200
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  06640300
      *                                                                 06640400
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  06640500
      *            SET  TI-CF06-88-RECH        TO TRUE                  06640600
      *                                                                 06641000
      *            MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 06641100
      *                                       WS-TEMP-XX                06641200
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)06641300
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 06641400
      *                                       WS-CT-NUMER               06641500
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)06641600
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *            MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  06641700
      *                                       TI-TR02-ORIGEN-RESPUESTA  06641800
      *            PERFORM 6100-OBTENER-MENSAJE                         06642000
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 06642100
      *                                                                 06642200
      *            MOVE WS-CODMSG-ESTRUCTURA                            06647300
      *                                    TO WS-COD-ERROR-07           06647400
      *            MOVE WS-PROGRAM-ID      TO WS-PROGRAM                06647500
      *                                                                 06647600
      *            MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        06647700
      *                                                                 06648000
      *            PERFORM 6300-ACTUALIZA-COMAREA                       06648100
      *            PERFORM 6200-GRABAR-LOG-EVENTOS                      06649000
      *            PERFORM 6000-FINAL                                   06650000
      *       END-IF                                                    06660000
      *    END-IF                                                       06670000
      *    .                                                            06671000
      ************************ FIN DE 1600-VERIFICAR-TRAMA              00160022
      *GNS-F                                                                    
      ************************                                          06686000
       1620-ACTUALIZA-COMAREA.                                          06690000
      ************************                                          06691000
      ******************************************************************06700000
      * ACTUALIZA COMMAREA CON CAMPO ERRADO                            *06710000
      ******************************************************************06711000
                                                                        06720100
           SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      06723200
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 06723300
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         06723400
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   06723500
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       06723600
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       06723700
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        06723800
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 06723300
           MOVE TI-TRR2-CANAL              TO TI-CF06-CANAL-CCE         06723400
NO HAY     MOVE SPACES                     TO TI-CF06-BIN-ADQUIRIENTE   06723500
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       06723600
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          06723700
           MOVE WS-DATE-LOCAL              TO TI-CF06-FECHA-TRANS       06723700
           MOVE TI-TRR2-CREATION-TIME      TO TI-CF06-HORA-TRANS        06723800
      *GNS-F                                                                    
           MOVE WS-FECHA-INI               TO TI-CF06-FECHA-PROCESO     06723900
           MOVE WS-HORA-INI                TO TI-CF06-HORA-PROCESO      06724000
           MOVE WS-CT-TI                   TO TI-CF06-CANAL-BCP         06724100
JCS                                     TI-TRR2-LIBRE-RECEPTOR(01:02)           
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-NRO-OPERACION-CNL 06724200
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF06-NRO-OPERACION-CNL 06724200
      *GNS-F                                                                    
AJUSTA*GNS-I                                                                    
AJUSTA*    MOVE WS-CODMSG-ESTRUCTURA       TO WS-CODMSG                 06724300
AJUSTA*GNS-F                                                                    
           .                                                            06840000
      ************************ FIN DE 1620-ACTUALIZA-COMAREA            07350000
      ***********************                                           07351000
      *1600-OBTIENE-NEXT-DAY.                                           00160022
      ***********************                                           07361000
      ******************************************************************07370000
      * OBTIENE EL ESTADO DE NEXT-DAY                                  *07380000
      ******************************************************************07381000
      *                                                                 00160022
      *    INITIALIZE BCNDCOMM-AREA                                     00160022
      *               REPLACING  ALPHANUMERIC DATA BY SPACES            00160022
      *                               NUMERIC DATA BY ZEROS             00160022
      *                                                                 00160022
      *    MOVE WS-EYEID-ND                    TO BCNDCOMM-EYE          00160022
      *    MOVE 'TOLD'                         TO BCNDCOMM-APLICACION   00160022
      *    MOVE '00'                           TO BCNDCOMM-COD-RET      00160022
      *    MOVE '0'                            TO BCNDCOMM-MOD-OP       00160022
      *    MOVE SPACES                         TO BCNDCOMM-FILLER-01    00160022
      *    MOVE TI-CW03-RTN-NEXT-DAY           TO WS-RTN-SGTE           00160022
      *    MOVE BCNDCOMM-AREA                  TO WS-CCAA               00160022
      *    MOVE LENGTH OF BCNDCOMM-AREA        TO WS-LGTH-CCAA          00160022
      *                                                                 00160022
      *    PERFORM  7200-RUT-LINK-GRAL                                  00160022
      *    MOVE WS-CCAA                        TO BCNDCOMM-AREA         00160022
      *                                                                 00160022
      *    IF  BCNDCOMM-COD-RET  EQUAL  ZEROES                          00160022
      *        MOVE BCNDCOMM-MOD-OP            TO WS-FLAG-NEXT-DAY      00160022
      *        MOVE 0                          TO WS-FLAG-NEXT-DAY      07581000
      *        IF  WS-IN-PROCESS OR WS-NEXT-DAY                         00160022
      *            PERFORM 1620-ACTUALIZA-COMAREA                       00160022
      *            OBTENER MENSAJE PARA CCE                             07631000
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  00160022
      *                                                                 00160022
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  00160022
      *            SET  TI-CF06-88-RECH        TO TRUE                  00160022
      *            MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 00160022
      *                                       WS-TEMP-XX                00160022
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)00160022
      *            MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)00160022
      *            MOVE WS-CT-1021         TO WS-CT-NUMER               00160022
      *            MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  00160022
      *            PERFORM 6100-OBTENER-MENSAJE                         00160022
      *                                                                 00160022
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 00160022
      *            PERFORM 6300-ACTUALIZA-COMAREA                       00160022
      *                                                                 00160022
      *            OBTENER MENSAJE INTERNO                              07639900
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  00160022
      *            SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  00160022
      *            MOVE 'TI0415'               TO TI-CF06-CODMSG-ESTRUCT00160022
      *                                           WS-CODMSG-ESTRUCTURA  00160022
      *                                           WS-COD-ERROR-07       00160022
      *            MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM        00160022
      *                                           WS-PROGRAM            00160022
      *            PERFORM 6100-OBTENER-MENSAJE                         00160022
      *            MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        00160022
      *                                                                 00160022
      *                                                                 00160022
      *            PERFORM 6200-GRABAR-LOG-EVENTOS                      00160022
      *            PERFORM 6000-FINAL                                   00160022
      *        ELSE                                                     00160022
      *            SET  WS-SI-LAST-RETRY           TO TRUE              00160022
      *                                                                 00160022
      *        END-IF                                                   00160022
      *    ELSE                                                         00160022
      *        PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *        OBTENER MENSAJE PARA CCE                                 07731000
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      00160022
      *                                                                 00160022
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      00160022
      *        SET  TI-CF06-88-RECH        TO TRUE                      00160022
      *        MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     00160022
      *                                   WS-TEMP-XX                    00160022
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    00160022
      *        MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     00160022
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    00160022
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   00160022
      *        MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      00160022
      *        PERFORM 6100-OBTENER-MENSAJE                             00160022
      *                                                                 00160022
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     00160022
      *                                                                 00160022
      *        OBTENER MENSAJE INTERNO                                  07739800
      *        MOVE BCNDCOMM-COD-RET       TO TI-CF06-CODMSG-ESTRUCT    00160022
      *                                       WS-COD-ERROR-07           00160022
      *        MOVE TI-CW03-RTN-NEXT-DAY   TO TI-CF06-PRGNOM            00160022
      *                                       WS-PROGRAM                00160022
      *        MOVE SPACE                  TO TI-CF06-TXTMSG            00160022
      *                                       WS-MENSAJE-TXT-EVE        00160022
      *                                                                 00160022
      *        PERFORM 6300-ACTUALIZA-COMAREA                           00160022
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          00160022
      *        PERFORM 6000-FINAL                                       00160022
      *     END-IF                                                      00160022
      *     .                                                           00160022
      ************************ FIN DE 1600-OBTIENE-NEXT-DAY             07881000
      **************                                                    07890000
       2000-PROCESO.                                                    07900000
      **************                                                    07901000
      ******************************************************************07910000
      * PROCESO PRINCIPAL LLAMAS SUBRUTINAS.                            07920000
      ******************************************************************07930000
      *                                                                 08070000
      *GNS-I                                                                    
      *    PERFORM 2100-OBTENER-NRO-OPERACION                           08071000
      *GNS-F                                                                    
           PERFORM 2200-ARMAR-TRAMA-RECEPTOR                            00160022
                                                                        08072000
      *GNS-I                                                                    
      *    IF  TI-TR02-MSGE-TYPE-ID   = WS-CT-0200                      08080000
      *        IF  TI-TR02-COD-PROCESO = WS-CT-800000                   08090000
      *            PERFORM 3000-CONSULTA                                08100000
      *                                                                 08101000
      *        END-IF                                                   08110000
      *        IF  TI-TR02-COD-PROCESO = WS-CT-490000                   08120000
      *            PERFORM 4000-TRANSFERENCIA                           08130000
      *                                                                 08131000
      *        END-IF                                                   08140000
      *    END-IF                                                       08150000
      *    IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201 AND                    08160000
      *        TI-TR02-COD-PROCESO  = WS-CT-490000                      08170000
      *        PERFORM 5000-REENVIO                                     08180000
      *                                                                 08181000
      *    END-IF                                                       08190000
           PERFORM 5000-CONFIRMACION-CANCELACION                        08100000
      *GNS-F                                                                    
           .                                                            08220000
      ************************ FIN DE 2000-PROCESO                      08221000
      *GNS-I                                                                    
      ****************************                                      08221100
      *2100-OBTENER-NRO-OPERACION.                                      08221200
      ****************************                                      08221300
      ******************************************************************08221400
      * ESTABLECER EL NOMBRE DEL CONTADOR ANTES DE USAR ESTE PROCESO    08221500
      ******************************************************************08221600
      *                                                                 08221700
      *    MOVE +0                      TO WS-NRO-OPER-COUNTER          08221800
      *                                                                 08221900
      *    IF  TI-CW03-88-CURRENT-DAY                                   00160022
      *        MOVE TI-CW03-SYS-NRO-OPER-TRAN    TO WS-NC-COUNTER-NAME  00160022
      *                                                                 00160022
      *    ELSE                                                         00160022
      *        MOVE TI-CW03-SYS-NRO-OPER-TRAN-ND TO WS-NC-COUNTER-NAME  00160022
      *                                                                 00160022
      *    END-IF                                                       00160022
      *                                                                 00160022
      *    EXEC CICS GET                                                08222000
      **         COUNTER (TI-CW03-SYS-NRO-OPER-TRAN)                    00160022
      *          COUNTER (WS-NC-COUNTER-NAME)                           00160022
      *            VALUE (WS-NRO-OPER-COUNTER)                          08222300
      *             RESP (WS-RESP)                                      08222400
      *            RESP2 (WS-RESP2)                                     08222500
      *    END-EXEC                                                     08222700
      *                                                                 08222800
      *    IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                      08222900
      *        PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      **       OBTENER MENSAJE PARA CCE                                 08223600
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08223700
      *                                                                 08223800
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      08223900
      *        SET  TI-CF06-88-RECH        TO TRUE                      08224000
      *        MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     08224100
      *                                   WS-TEMP-XX                    08224200
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    08224300
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *        MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     08224400
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    08224500
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   08224600
      *                                   TI-TR02-COD-RESP-AMPLIADO             
      *        MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      08224700
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             08224800
      *                                                                 08224900
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     08225000
      *        PERFORM 6300-ACTUALIZA-COMAREA                           08225100
      *                                                                 08225200
      **       OBTENER MENSAJE INTERNO                                  08225300
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08225400
      *        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      08225500
      *        MOVE 'TI0804'               TO TI-CF06-CODMSG-ESTRUCT    08225600
      *                                       WS-CODMSG-ESTRUCTURA      08225700
      *                                       WS-COD-ERROR-07           08225800
      *        MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            08225900
      *                                       WS-PROGRAM                08226000
      *        MOVE TI-CW03-SYS-NRO-OPER-TRAN                           08226100
      *                                    TO WS-VARMSG-RSO             08226200
      *                                                                 08226300
      *        PERFORM 6100-OBTENER-MENSAJE                             08226400
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            08226500
      *                                                                 08226600
      *                                                                 08226700
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          08226800
      *        PERFORM 6000-FINAL                                       08226900
      *     END-IF                                                      08227000
      *     .                                                           08227100
      *GNS-F                                                                    
      ***************************                                       00160022
       2200-ARMAR-TRAMA-RECEPTOR.                                       00160022
      ***************************                                       00160022
                                                                        00160022
      *GNS-I                                                                    
      *    MOVE LENGTH OF TI-CA02-AREA-COMUNICACION                     00160022
      *                                TO TI-CA02-LONG-REG              00160022
      *    SET  TI-CA02-88-AREA-TTIB   TO TRUE                          00160022
      *    MOVE TI-CW03-FLAG-NEXT-DAY  TO TI-CA02-FLAG-NEXT-DAY         00160022
      *                                                                 00160022
      *    MOVE WS-FILE-NM-MAESTRO     TO TI-CA02-FILE-NAME-MAESTRO     00160022
      *    MOVE WS-FILE-NM-MAESTRO-ALT                                  00160022
      *                                TO TI-CA02-FILE-NAME-MAESTRO-ALT 00160022
      *    MOVE WS-FILE-NM-MAESTRO-ALT2                                 00160022
      *                                TO TI-CA02-FILE-NAME-MAESTRO-ALT200160022
      *    MOVE WS-FILE-NM-EVEN-LOG    TO TI-CA02-FILE-NAME-EVEN-LOG    00160022
           MOVE LENGTH OF TI-CAR2-AREA-COMUNICACION                     00160022
                                       TO TI-CAR2-LONG-REG              00160022
           SET  TI-CAR2-88-AREA-TTIB   TO TRUE                          00160022
           MOVE TI-CW04-FLAG-NEXT-DAY  TO TI-CAR2-FLAG-NEXT-DAY         00160022
                                                                        00160022
           MOVE WS-FILE-NM-MAESTRO     TO TI-CAR2-FILE-NAME-MAESTRO     00160022
           MOVE WS-FILE-NM-MAESTRO-ALT                                  00160022
                                       TO TI-CAR2-FILE-NAME-MAESTRO-ALT 00160022
           MOVE WS-FILE-NM-MAESTRO-ALT3                                 00160022
                                       TO TI-CAR2-FILE-NAME-MAESTRO-ALT300160022
           MOVE WS-FILE-NM-EVEN-LOG    TO TI-CAR2-FILE-NAME-EVEN-LOG    00160022
      *GNS-F                                                                    
           .                                                            00160022
      ************************ FIN DE 2200-ARMAR-TRAMA-RECEPTOR         00160022
      *GNS-I                                                                    
      ***************                                                   08228000
      *3000-CONSULTA.                                                   08230000
      ***************                                                   08240000
      ******************************************************************08241000
      * LLAMA A LA CONSULTA*                                            08250000
      ******************************************************************08260000
      *                                                                 08270000
      *    MOVE WS-NRO-OPER-COUNTER        TO WS-NRO-OPER-COUNTER-TMP   08271000
      *    MOVE WS-NRO-OPER-COUNTER-TMP    TO TI-TR02-AUTORIZAT-ID-RESP 08272000
      *    MOVE TI-TR02-I-TRAMA            TO TI-CA02-REG-TRANS-DATA    00160022
      *                                                                 08273000
      **   EXEC CICS LINK PROGRAM(WS-PROG-CONSULTA)                     00160022
      **                 COMMAREA(TI-TR02-I-TRAMA)                      00160022
      **                   LENGTH(LENGTH OF TI-TR02-I-TRAMA)            00160022
      **                     RESP(WS-RESP)                              00160022
      **   END-EXEC                                                     00160022
      *                                                                 08330000
      *    EXEC CICS LINK PROGRAM(WS-PROG-CONSULTA)                     08280000
      *                  COMMAREA(TI-CA02-AREA-COMUNICACION)            00160022
      *                    LENGTH(LENGTH OF TI-CA02-AREA-COMUNICACION)  00160022
      *                      RESP(WS-RESP)                              08310000
      *    END-EXEC                                                     08320000
      *                                                                 08330000
      *    IF  WS-RESP EQUAL TO DFHRESP(NORMAL)                         08340000
      *        MOVE TI-CA02-REG-TRANS-DATA     TO TI-TR02-I-TRAMA       00160022
      *        MOVE TI-TR02-I-TRAMA            TO DFHCOMMAREA           08350000
      *                                                                 08360000
      *    ELSE                                                         08370000
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08420200
      *                                                                 08420300
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      08420400
      *        SET  TI-CF06-88-RECH        TO TRUE                      08420500
      *        MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 08420600
      *                                       WS-TEMP-XX                08420700
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)08420800
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *        MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 08420900
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)08421000
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               08421100
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *        MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  08421200
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             08421300
      *                                                                 08421400
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 08421500
      *        PERFORM 6300-ACTUALIZA-COMAREA                           08421600
      *                                                                 08421700
      **       OBTENER MENSAJE INTERNO                                  08421800
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08421900
      *        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      08422000
      *        MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    08422100
      *                                       WS-CODMSG-ESTRUCTURA      08422200
      *                                       WS-COD-ERROR-07           08422300
      *        MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            08422400
      *                                       WS-PROGRAM                08422500
      *        MOVE 'LINK'                 TO WS-VARMSG-FUN             08422600
      *        MOVE WS-PROG-CONSULTA       TO WS-VARMSG-RSO             08422700
      *                                                                 08422800
      *        PERFORM 6100-OBTENER-MENSAJE                             08422900
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            08423000
      *                                                                 08423100
      *                                                                 08423200
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          08423300
      *        PERFORM 6000-FINAL                                       08423400
      *                                                                 08424000
      *    END-IF                                                       08430000
      *    .                                                            08430100
      ************************ FIN DE 3000-CONSULTA                     08431000
      *GNS-F                                                                    
      *GNS-I                                                                    
      ********************                                              08432000
      *4000-TRANSFERENCIA.                                              08450000
      ********************                                              08451000
      ***************************************************************** 08460000
      * ASIGNA A COPY MAESTRO DE TRANSFERENCIAS E INVOCA CONSULTA       08470000
      ***************************************************************** 08480000
      *                                                                 08481000
      *    PERFORM 4050-GESTIONAR-SEMAF-PROC-NOR                        00084358
      *    PERFORM 4100-CONSULTA-PREVIA                                 08490000
      *    PERFORM 4200-LLENA-RECORD-TRANF                              08491000
      *    PERFORM 5100-GRABAR-ACTUALIZACION                            08500000
      *    PERFORM 5500-PROCESA-TRANSFENCIA                             08510000
      *    .                                                            08510100
      ************************ FIN DE 4000-TRANSFERENCIA                08511000
      *GNS-F                                                                    
      *******************************                                   00084358
       4050-GESTIONAR-SEMAF-PROC-NOR.                                   00084358
      *******************************                                   00084358
      ******************************************************************00084358
      * REALIZA INICIO Y EVALUA USO DE SEMAFORO PARA TRANSFERENCIA     *00084358
      * DE PROCESO NORMAL                                              *00084358
      ******************************************************************00084358
                                                                        00084358
           MOVE SPACES                     TO TI-CF06-REG-KEY-TRANS     00084358
                                                                        00084358
           SET  TI-CF06-88-COD-PROCESO-TRN TO TRUE                      00084358
           SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      00084358
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 00084358
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         00084358
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   00084358
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       00084358
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       00084358
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        00084358
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 06723300
           MOVE TI-TRR2-CANAL              TO TI-CF06-CANAL-CCE         06723400
NO HAY     MOVE SPACES                     TO TI-CF06-BIN-ADQUIRIENTE   06723500
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       06723600
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          06723700
           MOVE WS-DATE-LOCAL              TO TI-CF06-FECHA-TRANS       06723700
           MOVE TI-TRR2-CREATION-TIME      TO TI-CF06-HORA-TRANS        06723800
      *GNS-F                                                                    
                                                                        00084358
           MOVE TI-CF06-REG-KEY-TRANS      TO WS-RESOURCE-KEY-TRANSF    00084358
                                                                        00084358
           EXEC CICS ENQ                                                00084358
                RESOURCE(WS-RESOURCE)                                   00084358
                LENGTH(48)                                              00084358
                NOSUSPEND                                               00084358
                RESP(WS-RESP)                                           00084358
           END-EXEC                                                     00084358
                                                                        00084358
           EVALUATE WS-RESP                                             00084358
               WHEN DFHRESP(NORMAL)                                     00084358
                   SET  WS-ENQ-RESOURCE-SI TO TRUE                      00084358
                                                                        00084358
               WHEN OTHER                                               00084358
                   EXEC CICS DELAY INTERVAL(30)                         00084358
                   END-EXEC                                             00084358
                                                                        00084358
      *GNS-I                                                                    
      *            MOVE SPACES             TO TI-TR02-RESPONSE-CODE-CCE 11800000
      *                                       TI-TR02-COD-RESP-AMPLIADO 11801100
      *                                       TI-TR02-ORIGEN-RESPUESTA  11802100
      *                                       TI-TR02-MENSAJE-RESPUESTA 11804000
      *                                       TI-TR02-AUTORIZAT-ID-RESP 11806000
                   MOVE SPACES             TO TI-TRR2-RESPONSE-CODE-CCE 11800000
                                              TI-TRR2-COD-RESP-AMPLIADO 11801100
                   MOVE ZEROES             TO TI-CAR2-AUTORIZAT-ID-RESP 11806000
      *GNS-F                                                                    
                                                                        00084358
                   PERFORM 6000-FINAL                                   00084358
                                                                        00084358
           END-EVALUATE                                                 00084358
           .                                                            00084358
      ************************ FIN DE 4050-GESTIONAR-SEMAF-PROC-NOR     00084358
      ***************************                                       08512000
      *GNS-I                                                                    
      *4100-CONSULTA-PREVIA.                                            08513000
       4100-TRANSFERENCIA-PREVIA.                                       08513000
      *GNS-F                                                                    
      ***************************                                       08514000
      ****************************************************************  08515000
      * ASIGNA DATOS A COPY MAESTRO DE TRANSFERENCIAS                   08516000
      ****************************************************************  08517000
                                                                        08517100
      *GNS-I                                                                    
      *    MOVE TI-TR02-ID-TRANS-CCE-ONL-OR                             08517200
      *                                TO TI-CF06-ID-TRANS-CCE-ONLINE   08517300
           EVALUATE TI-CAR2-COD-PROCESO-CNF-CAN                                 
               WHEN WS-CT-00                                                    
                   MOVE TI-TRR2-INSTRUCTION-ID                          08517200
                                       TO TI-CF06-INSTRUCTION-ID        08517300
               WHEN WS-CT-05                                                    
                   MOVE TI-TRR2-REF-INSTRUCTION-ID                      08517200
                                       TO TI-CF06-INSTRUCTION-ID        08517300
               WHEN OTHER                                                       
                   PERFORM 1620-ACTUALIZA-COMAREA                       00160022
      *            OBTENER MENSAJE PARA CCE                             05772000
                   MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE     05777000
                                          WS-TEMP-XX                    05778000
                   MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO     05779100
                                          WS-TEMP-XXXX                          
                   MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA      05779400
                                                                        05779800
      *            OBTENER MENSAJE INTERNO                              05779900
                                                                        05780600
                   PERFORM 6300-ACTUALIZA-COMAREA                       05780700
                   MOVE SPACES         TO TI-CA15-I-O-MENSAJES              0827
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      0827
                   MOVE 'TI0403'       TO TI-CF06-CODMSG-ESTRUCT            0827
                                          WS-CODMSG-ESTRUCTURA              0827
                                          WS-COD-ERROR-07                   0827
                   MOVE WS-PROGRAM-ID  TO TI-CF06-PRGNOM                    0827
                                          WS-PROGRAM                        0827
                   MOVE WS-CT-COD-PROCESO-CNF-CAN                           0016
                                       TO WS-VARMSG-RSO                     0016
                   MOVE TI-CAR2-COD-PROCESO-CNF-CAN                         0827
                                       TO WS-VARMSG-ARG                     0827
                                                                            0827
                   PERFORM 6100-OBTENER-MENSAJE                             0827
                   MOVE WS-MENSAJE-TXT TO TI-CF06-TXTMSG                    0827
                                          WS-MENSAJE-TXT-EVE                0827
                   PERFORM 6200-GRABAR-LOG-EVENTOS                      05780800
                   PERFORM 6000-FINAL                                   05780900
           END-EVALUATE                                                         
      *GNS-F                                                                    
                                                                        08517400
      *    EXEC CICS READ   FILE (TI-CW03-FILE-MAESTRO-ALT2)            00160022
      *GNS-I                                                                    
      *    EXEC CICS READ   FILE (WS-FILE-NM-MAESTRO-ALT2)              00160022
           EXEC CICS READ   FILE (WS-FILE-NM-MAESTRO-ALT3)              00160022
      *GNS-F                                                                    
                            INTO (TI-CF06-REG-TRANS)                    08517600
                          LENGTH (LENGTH OF TI-CF06-REG-TRANS)          08517700
      *GNS-I                                                                    
      *                   RIDFLD (TI-CF06-ID-TRANS-CCE-ONLINE)          08517800
      *                KEYLENGTH (LENGTH OF TI-CF06-ID-TRANS-CCE-ONLINE)08517900
                          RIDFLD (TI-CF06-INSTRUCTION-ID)               08517800
                       KEYLENGTH (LENGTH OF TI-CF06-INSTRUCTION-ID)     08517900
      *GNS-F                                                                    
                            RESP (WS-RESP)                              08518000
           END-EXEC                                                     08518100
      *                                                                 08518200
      *GNS-I                                                                    
      *    IF  WS-RESP = DFHRESP (NORMAL)                               08518300
           EVALUATE WS-RESP                                                     
             WHEN DFHRESP (NORMAL)                                              
      *GNS-F                                                                    
      *GNS-I                                                                    
      *        MOVE TI-CF06-INDI-MISMO-CLIENTE                          08518400
      *                                    TO TI-TR02-INDI-MISMO-CLIENTE08518500
      *        MOVE TI-CF06-APE-PAT-CLI-BENE                            08518600
      *                                    TO TI-TR02-APE-PAT-CLI-BENE  08518700
      *        MOVE TI-CF06-APE-MAT-CLI-BENE                            08518800
      *                                    TO TI-TR02-APE-MAT-CLI-BENE  08518900
      *        MOVE TI-CF06-NOMBRE-CLI-BENE                             08519000
      *                                    TO TI-TR02-NOMBRE-CLI-BENE   08520000
               IF TI-CAR2-88-COD-PROCESO-CNF                                    
                   IF TI-CF06-CAUSAL EQUAL 'AEC'                                
                       PERFORM 4150-COMPARA-CCI-CLI-BENEFICIA                   
                   ELSE                                                         
                       PERFORM 4160-COMPARA-COD-TARJETA-CRED                    
                   END-IF                                                       
                   PERFORM 4170-COMPARA-IMPORTE                                 
               END-IF                                                           
               MOVE TI-CF06-TRACE-ADQUIRIENTE                           08519000
                                          TO TI-TRR2-TRACE-ADQUIRIENTE  08520000
               MOVE TI-CF06-CANAL-CCE     TO TI-TRR2-CANAL              08519000
               MOVE TI-CF06-TERMINAL-ID   TO TI-TRR2-TERMINAL-ID        08519000
               MOVE WS-FECHA-INI(1:4)     TO WS-YEAR-LOCAL              08519000
               MOVE TI-CF06-FECHA-TRANS   TO WS-DATE-LOCAL              08519000
               MOVE WS-CREATION-DATE      TO TI-TRR2-CREATION-DATE      08519000
               MOVE TI-CF06-HORA-TRANS    TO TI-TRR2-CREATION-TIME      08519000
      *                                                                         
               MOVE TI-CF06-NOM-APE-ORIG  TO TI-TRR2-NOM-APE-ORIG       08519000
AJUSTA         MOVE TI-CF06-NRO-DOC-CLI-ORIG                            08519000
                                          TO TI-TRR2-NRO-DOC-CLI-ORIG   08519000
AJUSTA         MOVE TI-CF06-TIP-DOC-CLI-ORIG                            08519000
                                          TO TI-TRR2-TIP-DOC-CLI-ORIG   08519000
               MOVE TI-CF06-TELEF-CLI-ORIG                              08519000
                                          TO TI-TRR2-TELEF-CLI-ORIG     08519000
               MOVE TI-CF06-DIRECC-CLI-ORIG                             08519000
                                          TO TI-TRR2-DIRECC-CLI-ORIG    08519000
               MOVE TI-CF06-NRO-CEL-CLI-ORIG                            08519000
                                          TO TI-TRR2-NRO-CEL-CLI-ORIG   08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-TRANS-EXTENDIDA    08519000
AJUSTA         MOVE TI-CF06-DIRECC-CLI-BENE                             08519000
                                          TO TI-TRR2-DIRECC-CLI-BENE    08519000
               MOVE TI-CF06-TELEF-CLI-BENE                              08519000
                                          TO TI-TRR2-TELEF-CLI-BENE     08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-COD-TARJETA-CRED   08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-INSTRUCTION-ID     08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-BRANCH-ID          08519000
               MOVE TI-CF06-NOM-APE-BENE                                08519000
                                          TO TI-TRR2-NOM-APE-BENE       08519000
AJUSTA         MOVE TI-CF06-TIP-DOC-CLI-BENE                            08519000
                                          TO TI-TRR2-TIP-DOC-CLI-BENE   08519000
CHANCA         MOVE TI-CF06-INDI-MISMO-CLIENTE                          08519000
                                          TO TI-TRR2-INDI-MISMO-CLIENTE 08519000
CHANCA         MOVE TI-CF06-NRO-REFERENCIA                              08519000
                                          TO TI-TRR2-REF-TRANSFERENCIA  08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-IMPORTE-COMISION   08519000
               MOVE TI-CF06-CODIGO-TARIFA                               08519000
                                          TO TI-TRR2-CODIGO-TARIFA      08519000
               MOVE TI-CF06-CRITERIO-APLICA                             08519000
                                          TO TI-TRR2-CRITERIO-APLICACION08519000
                                                                                
TOPICO*-- MVP00127821 --\                                               08519000
      *        STRING  '+51'  TI-CF06-NRO-CEL-CLI-BENE                  08519000
      *          DELIMITED  BY  SIZE    INTO TI-TRR2-NRO-CEL-CLI-BENE   08519000
               MOVE TI-CF06-NRO-CEL-CLI-BENE                                    
                                          TO TI-TRR2-NRO-CEL-CLI-BENE           
               MOVE TI-CF06-IDC-BEN                                     08519000
                                          TO TI-TRR2-NRO-DOC-CLI-BENE   08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-REF-INSTRUCTION-ID 08519000
               MOVE TI-CF06-REF-INSTRUCTION-ID                          08519000
                                       TO TI-TRR2-CON-INSTRUCTION-ID    08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-CCI-CLI-ORIGINANTE 08519000
               MOVE TI-CF06-CCI-CLI-ORIG                                08519000
                                          TO TI-TRR2-CCI-CLI-ORIGINANTE 08519000
TOPICO*-- MVP00153165 --\                                               08519000
JCS   *        MOVE TI-CF06-CONCEPT-COBRO                               08519000
JCS   *                                   TO TI-TRR2-CRITERIO-APLICACION08519000
TOPICO*-- MVP00153165 --/                                               08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-CCI-CLI-BENEFICIA  08519000
               MOVE TI-CF06-CCI-CLI-BENEFICIA                           08519000
                                          TO TI-TRR2-CCI-CLI-BENEFICIA  08519000
                                                                                
               IF TI-CF06-COD-MON EQUAL '0001'                                  
                  MOVE 604                TO TI-TRR2-TRANS-CURREN-CODE          
               ELSE                                                             
                  MOVE 840                TO TI-TRR2-TRANS-CURREN-CODE          
               END-IF                                                           
                                                                                
               MOVE TI-CF06-TIPO-PERSONA                                08519000
                                          TO TI-TRR2-TIPO-PERSONA       08519000
TOPICO*-- MVP00127821 --/                                               08519000
                                                                                
               MOVE TI-CF06-CONCEPT-COBRO                               08519000
                                          TO TI-TRR2-CONCEPT-COBRO      08519000
               MOVE TI-CF06-GLOSA                                       08519000
                                          TO TI-TRR2-GLOSA              08519000
               MOVE TI-CF06-IMPORT-SUELDO-BRUTO                         08519000
                                          TO TI-TRR2-IMPORT-SUELDO-BRUTO08519000
               MOVE TI-CF06-INDICADOR-PAG-HAB                           08519000
                                          TO TI-TRR2-INDICADOR-PAG-HAB  08519000
               MOVE TI-CF06-MES-PAGO                                    08519000
                                          TO TI-TRR2-MES-PAGO           08519000
               MOVE TI-CF06-ANIO-PAGO                                   08519000
                                          TO TI-TRR2-ANIO-PAGO          08519000
CHANCA         MOVE TI-CF06-FECHA-LIQUIDA                               08519000
                                          TO TI-TRR2-FECHA-LIQUIDACION  08519000
VIENE *        MOVE                                                     08519000
VIENE *                                   TO TI-TRR2-MONTO-LIQUIDACION  08519000
      *MVP139677--\                                                             
 MAVD      MOVE TI-CF06-ENTIDAD-ORIGEN    TO TI-TRR2-ENTIDAD-ORIGEN     12151800
 MAVD      MOVE TI-CF06-ENTIDAD-DESTINO   TO TI-TRR2-ENTIDAD-DESTINO    12151800
 MAVD      MOVE TI-CF06-INSTRUCTION-ID    TO TI-TRR2-INSTRUCTION-ID     12151800
 MAVD      MOVE TI-CF06-REF-INSTRUCTION-ID  TO                          12151800
 MAVD                                       TI-TRR2-REF-INSTRUCTION-ID          
 MAVD      MOVE TI-CF06-REF-INSTRUCTION-ID  TO                          12151800
 MAVD                                       TI-TRR2-CON-INSTRUCTION-ID          
           MOVE TI-CF06-CANAL-BCP      TO TI-TRR2-LIBRE-RECEPTOR(01:02) 06724100
      *MVP139677--/                                                             
               IF TI-CAR2-88-COD-PROCESO-CNF                                    
CHANCO             MOVE TI-CF06-FECHA-PROCESO                           06723900
                                          TO TI-TRR2-RESPONSE-DATE      06723900
                   MOVE TI-CF06-HORA-PROCESO(1:2)                       06724000
                                          TO WS-RESPONSE-HOR            06724000
                   MOVE TI-CF06-HORA-PROCESO(4:2)                       06724000
                                          TO WS-RESPONSE-MIN            06724000
                   MOVE TI-CF06-HORA-PROCESO(7:2)                       06724000
                                          TO WS-RESPONSE-SEG            06724000
CHANCO             MOVE WS-RESPONSE-TIME  TO TI-TRR2-RESPONSE-TIME      06724000
               END-IF                                                           
               MOVE TI-CF06-REQUEST-ID-BCP                              08519000
                                          TO TI-CAR2-REQUEST-ID-BCP     08519000
               MOVE TI-CF06-AUTORIZAT-ID-RESP                           08519000
                                          TO TI-CAR2-AUTORIZAT-ID-RESP  08519000
      *GNS-F                                                                    
                                                                        08521400
      *GNS-I                                                                    
             WHEN DFHRESP (NOTFND)                                      08518300
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *        OBTENER MENSAJE PARA CCE                                 08521700
               SET  TI-CF06-88-RECH        TO TRUE                      08522100
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     08522200
                                          WS-TEMP-XX                    08522300
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     08522500
                                          WS-TEMP-XXXX                          
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      08522800
               PERFORM 6300-ACTUALIZA-COMAREA                           08523200
                                                                        08523300
      *        OBTENER MENSAJE INTERNO                                  08523400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08523500
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      08523600
               MOVE 'TI0403'               TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
               IF TI-CAR2-88-COD-PROCESO-CNF                                    
                   MOVE WS-CT-INSTRUCTION-ID                            00160022
                                           TO WS-VARMSG-RSO             00160022
                   MOVE TI-TRR2-INSTRUCTION-ID(01:15)                   08272800
                                           TO WS-VARMSG-RSO(06:15)      08272800
                   MOVE TI-TRR2-INSTRUCTION-ID(16:20)                   08272800
                                           TO WS-VARMSG-ARG             08272800
               ELSE                                                             
                   MOVE WS-CT-REF-INSTRUCTION-ID                        00160022
                                           TO WS-VARMSG-RSO             00160022
                   MOVE TI-TRR2-REF-INSTRUCTION-ID(01:15)               08272800
                                           TO WS-VARMSG-RSO(06:15)      08272800
                   MOVE TI-TRR2-REF-INSTRUCTION-ID(16:20)               08272800
                                           TO WS-VARMSG-ARG             08272800
               END-IF                                                           
                                                                        08272900
               PERFORM 6100-OBTENER-MENSAJE                             08273000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            08524800
                                              WS-MENSAJE-TXT-EVE        08524900
                                                                        08525000
               PERFORM 6200-GRABAR-LOG-EVENTOS                          08525100
               PERFORM 6000-FINAL                                       08525200
      *GNS-F                                                                    
      *GNS-I                                                                    
      *    ELSE                                                         08521500
             WHEN OTHER                                                 08518300
      *GNS-F                                                                    
               MOVE WS-RESP                TO WS-RESP-TXT               08521600
      *GNS-I                                                                    
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *GNS-F                                                                    
      *        OBTENER MENSAJE PARA CCE                                 08521700
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08521800
      *                                                                 08521900
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      08522000
      *        SET  TI-CF06-88-RECH        TO TRUE                      08522100
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     08522200
                                          WS-TEMP-XX                    08522300
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    08522400
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     08522500
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    08522600
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   08522700
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                                          WS-TEMP-XXXX                          
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      08522800
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             08522900
      *                                                                 08523000
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     08523100
      *GNS-F                                                                    
               PERFORM 6300-ACTUALIZA-COMAREA                           08523200
                                                                        08523300
      *        OBTENER MENSAJE INTERNO                                  08523400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      08523500
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      08523600
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    08523700
                                              WS-CODMSG-ESTRUCTURA      08523800
                                              WS-COD-ERROR-07           08523900
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            08524000
                                              WS-PROGRAM                08524100
      *GNS-I                                                                    
      *        MOVE 'READ'                 TO WS-VARMSG-FUN             08524200
      *GNS-F                                                                    
      *        MOVE TI-CW03-FILE-MAESTRO-ALT2                           00160022
      *GNS-I                                                                    
      *        MOVE WS-FILE-NM-MAESTRO-ALT2                             00160022
               MOVE WS-FILE-NM-MAESTRO-ALT3                             00160022
      *GNS-F                                                                    
                                           TO WS-VARMSG-RSO             08524400
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             08524500
                                                                        08524600
               PERFORM 6100-OBTENER-MENSAJE                             08524700
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            08524800
                                              WS-MENSAJE-TXT-EVE        08524900
                                                                        08525000
               PERFORM 6200-GRABAR-LOG-EVENTOS                          08525100
               PERFORM 6000-FINAL                                       08525200
      *GNS-I                                                                    
      *    END-IF                                                       08525300
           END-EVALUATE                                                 08525300
      *GNS-F                                                                    
           .                                                            08718600
      ************************ FIN DE 4100-TRANSFERENCIA-PREVIA         08718700
      *GNS-I                                                                    
      ********************************                                  08719000
       4150-COMPARA-CCI-CLI-BENEFICIA.                                          
      ********************************                                  08719000
                                                                        07230000
           IF TI-TRR2-CCI-CLI-BENEFICIA EQUAL TI-CF06-CCI-CLI-BENEFICIA 14261000
              CONTINUE                                                  14261000
           ELSE                                                         14261000
              PERFORM 1620-ACTUALIZA-COMAREA                            00160022
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
              MOVE WS-CT-FF02             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-TEMP-XXXX               14269300
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                                                        14269900
              PERFORM 6300-ACTUALIZA-COMAREA                            07790600
                                                                        14269900
      *       OBTENER MENSAJE INTERNO                                   14270000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0411'               TO TI-CF06-CODMSG-ESTRUCT         0827
                                             WS-CODMSG-ESTRUCTURA           0827
                                             WS-COD-ERROR-07                0827
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM                 0827
                                             WS-PROGRAM                     0827
              MOVE WS-CT-CCI-CLI-BENEFICIA                                  0016
                                          TO WS-VARMSG-RSO                  0016
              MOVE TI-TRR2-CCI-CLI-BENEFICIA                                0827
                                          TO WS-VARMSG-ARG                  0827
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 6200-GRABAR-LOG-EVENTOS                           07680800
              PERFORM 6000-FINAL                                        07680900
           END-IF                                                       14271700
           .                                                                    
      ************************ FIN DE 4150-COMPARA-CCI-CLI-BENEFICIA    08718700
      *GNS-F                                                                    
      *GNS-I                                                                    
      *******************************                                   08719000
       4160-COMPARA-COD-TARJETA-CRED.                                           
      *******************************                                   08719000
                                                                        07230000
           IF TI-TRR2-COD-TARJETA-CRED EQUAL TI-CF06-COD-TARJETA-CRED   14261000
              CONTINUE                                                  14261000
           ELSE                                                         14261000
              PERFORM 1620-ACTUALIZA-COMAREA                            00160022
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
              MOVE WS-CT-FF02             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-TEMP-XXXX               14269300
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                                                        14269900
              PERFORM 6300-ACTUALIZA-COMAREA                            07790600
                                                                        14269900
      *       OBTENER MENSAJE INTERNO                                   14270000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0411'               TO TI-CF06-CODMSG-ESTRUCT         0827
                                             WS-CODMSG-ESTRUCTURA           0827
                                             WS-COD-ERROR-07                0827
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM                 0827
                                             WS-PROGRAM                     0827
              MOVE WS-CT-COD-TARJETA-CRED                                   0016
                                          TO WS-VARMSG-RSO                  0016
              MOVE TI-TRR2-COD-TARJETA-CRED                                 0827
                                          TO WS-VARMSG-ARG                  0827
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 6200-GRABAR-LOG-EVENTOS                           07680800
              PERFORM 6000-FINAL                                        07680900
           END-IF                                                       14271700
           .                                                                    
      ************************ FIN DE 4160-COMPARA-COD-TARJETA-CRED     08718700
      *GNS-F                                                                    
      *GNS-I                                                                    
      **********************                                            08719000
       4170-COMPARA-IMPORTE.                                                    
      **********************                                            08719000
                                                                        07230000
           MOVE TI-TRR2-IMPORTE            TO WS-TR02-IMPORTE-R         06460000
           COMPUTE WS-TR02-IMPORTE-R = WS-TR02-IMPORTE-R / 100          09142000
           END-COMPUTE                                                  09143000
           MOVE WS-TR02-IMPORTE-R          TO WS-TI-IMPORTE-E                   
                                                                        07230000
           IF WS-TI-IMPORTE-E EQUAL TI-CF06-IMPORTE                     14261000
              CONTINUE                                                  14261000
           ELSE                                                         14261000
              PERFORM 1620-ACTUALIZA-COMAREA                            00160022
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
              MOVE WS-CT-FF02             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-TEMP-XXXX               14269300
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                                                        14269900
              PERFORM 6300-ACTUALIZA-COMAREA                            07790600
                                                                        14269900
      *       OBTENER MENSAJE INTERNO                                   14270000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0411'               TO TI-CF06-CODMSG-ESTRUCT         0827
                                             WS-CODMSG-ESTRUCTURA           0827
                                             WS-COD-ERROR-07                0827
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM                 0827
                                             WS-PROGRAM                     0827
              MOVE WS-CT-IMPORTE          TO WS-VARMSG-RSO                  0016
              MOVE WS-TI-IMPORTE-E        TO WS-VARMSG-ARG                  0827
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 6200-GRABAR-LOG-EVENTOS                           07680800
              PERFORM 6000-FINAL                                        07680900
           END-IF                                                       14271700
           .                                                                    
      ************************ FIN DE 4170-COMPARA-IMPORTE              08718700
      *GNS-F                                                                    
      *GNS-I                                                                    
      *************************                                         08719000
      *4200-LLENA-RECORD-TRANF.                                         08720000
      *************************                                         08721000
      ****************************************************************  08730000
      * ASIGNA DATOS A COPY MAESTRO DE TRANSFERENCIAS                   08740000
      ****************************************************************  08750000
      *    SET  TI-CF06-88-COD-PROCESO-TRN TO TRUE                      08760000
      *    SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      08770000
      *    SET  TI-CF06-88-AFECT-CNTBL-NO  TO TRUE                      00160022
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 08780000
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         08790000
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   08800000
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       08810000
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       08820000
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        08830000
      *    MOVE WS-FECHA-INI               TO TI-CF06-FECHA-PROCESO     08840000
      *    MOVE WS-HORA-INI                TO TI-CF06-HORA-PROCESO      08850000
      *    MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)TO TI-CF06-CODIGO-BCO-EMI    08860000
      *    MOVE WS-CT-TI                   TO TI-CF06-CANAL-BCP         08861000
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-NRO-OPERACION-CNL 08870000
      *    SET  TI-CF06-88-PEND            TO TRUE                      08880000
      *    SET  TI-CF06-88-NO-REENV        TO TRUE                      08890000
      *    MOVE SPACES                     TO TI-CF06-NUM-LIQ-I         08900000
      *    MOVE TI-TR02-TIPO-PROCESO       TO TI-CF06-TIPO-PROCESO      08910000
      *    MOVE TI-TR02-FECHA-HORA-PROC    TO TI-CF06-FECHA-PROCESO-CCE 08920000
      *    MOVE TI-TR02-FECHA-PROCESO      TO TI-CF06-FECHA-PROCE-CCE   00160022
      *    MOVE TI-TR02-NRO-REFERENCIA     TO TI-CF06-NRO-REFERENCIA    08930000
      *    MOVE WS-NRO-OPER-COUNTER        TO WS-NRO-OPER-COUNTER-TMP   08980000
      *    MOVE WS-NRO-OPER-COUNTER-TMP    TO TI-TR02-AUTORIZAT-ID-RESP 08990000
      *    MOVE TI-TR02-AUTORIZAT-ID-RESP  TO TI-CF06-AUTORIZAT-ID-RESP 09000000
      *    MOVE SPACES                     TO TI-CF06-RESPONSE-CODE-CCE 09010000
      *    MOVE TI-TR02-COMERCIO           TO TI-CF06-COMERCIO          09020000
      *    MOVE TI-TR02-CARD-ACEPTOR-LOCA  TO TI-CF06-CARD-ACEPTOR-LOCA 09030000
      *    MOVE SPACES                     TO TI-CF06-COD-RESP-AMPLIADO 09040000
      *    MOVE SPACES                     TO TI-CF06-ORIGEN-RESPUESTA  09050000
      *    MOVE SPACES                     TO TI-CF06-MENSAJE-RESPUESTA 09060000
      *    MOVE TI-TR02-RUTEO              TO TI-CF06-ENT-BEN           06390000
      *    MOVE TI-TR02-COD-APLICACION     TO TI-CF06-COD-APLICACION    06400000
      *    MOVE TI-TR02-TIPO-SESION        TO TI-CF06-TIPO-SESION       06410000
      *    PERFORM 5300-BUSCAR-MON                                      09100000
      *    PERFORM 5400-BUSCAR-CAUSAL                                   09110000
      *    MOVE SPACES                     TO TI-CF06-TIP-PAGO          09120000
      *                                                                 09140100
      *    MOVE TI-TR02-IMPORTE            TO WS-TR02-IMPORTE-R         06460000
      *    COMPUTE WS-TR02-IMPORTE-R = WS-TR02-IMPORTE-R / 100          09142000
      *    END-COMPUTE                                                  09143000
      *    MOVE WS-TR02-IMPORTE-R          TO TI-CF06-IMPORTE           09144000
      *                                                                 09145000
      *    MOVE TI-TR02-ID-TRANS-CCE-ONLINE                             09150000
      *                                TO TI-CF06-ID-TRANS-CCE-ONLINE   09160000
      *    MOVE TI-TR02-ID-TRANS-CCE-ONL-OR                             09170000
      *                                TO TI-CF06-ID-TRANS-CCE-ONL-ORG  09180000
      *    MOVE TI-TR02-ID-SESION-APLICA   TO TI-CF06-ID-SESION-APLICA  09190000
      *    MOVE TI-TR02-CONCEPT-COBRO-TARI                              09200000
      *                                    TO TI-CF06-CONCEPT-COBRO-TARI09210000
      *    MOVE TI-TR02-CODIGO-TARIFA      TO TI-CF06-CODIGO-TARIFA     09220000
      *    MOVE ZEROS                      TO TI-CF06-IMPORTE-COMISION  09230000
      *    MOVE TI-TR02-IMPORTE-COMISION   TO WS-TR02-IMPORTE-COMI-R            
      **                                                                09250000
      *    COMPUTE WS-TR02-IMPORTE-COMI-R = WS-TR02-IMPORTE-COMI-R / 10009260000
      *    END-COMPUTE                                                  09270000
      **                                                                09280000
      *    IF  TI-TR02-SIGNO-COMISION = '-'                                     
      *        COMPUTE TI-CF06-IMP-COM-INTERB =                         09300000
      *                WS-TR02-IMPORTE-COMI-R * -1                      09310000
      *        END-COMPUTE                                              09320000
      *                                                                 09321000
      *    ELSE                                                         09330000
      *        MOVE WS-TR02-IMPORTE-COMI-R TO TI-CF06-IMP-COM-INTERB    09340000
      *                                                                 09341000
      *    END-IF                                                       09350000
      *    MOVE ZEROS                      TO TI-CF06-IMP-TOT           09360000
      *    MOVE TI-TR02-CRITERIO-APLICACION                             09370000
      *                                    TO TI-CF06-CRITERIO-APLICA   09371000
      *    MOVE TI-TR02-REF-TRANSFERENCIA  TO TI-CF06-REF-TRANSFERENCIA 09380000
      *    MOVE TI-TR02-INDICADOR-PAG-HAB  TO TI-CF06-INDICADOR-PAG-HAB 09390000
      *    MOVE TI-TR02-MES-PAGO           TO TI-CF06-MES-PAGO          09400000
      *    MOVE TI-TR02-ANIO-PAGO          TO TI-CF06-ANIO-PAGO         09410000
      *    MOVE TI-TR02-IMPORT-SUELDO-BRUTO                             09420000
      *                                TO TI-CF06-IMPORT-SUELDO-BRUTO   09430000
      *    MOVE TI-TR02-NRO-CORTE          TO TI-CF06-NRO-CORTE         09440000
      *    MOVE TI-TR02-ID-ALERTA          TO TI-CF06-ID-ALERTA         09450000
      *    MOVE TI-TR02-ENTIDAD-ORIGEN     TO TI-CF06-ENTIDAD-ORIGEN    09460000
      *    MOVE TI-TR02-CCI-CLI-ORIGINANTE TO TI-CF06-CCI-CLI-ORIG      09470000
      *    MOVE TI-TR02-TIPO-PERSONA       TO TI-CF06-TIPO-PERSONA      09480000
      *    MOVE SPACES                     TO TI-CF06-IDC-ORI           09490000
      *    MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO TI-CF06-TIP-DOC-CLI-ORIG  06830000
      *    MOVE TI-TR02-NRO-DOC-CLI-ORIG   TO TI-CF06-NRO-DOC-CLI-ORIG  06840000
      *    MOVE TI-TR02-APE-PAT-CLI-ORIG   TO TI-CF06-APE-PAT-CLI-ORIG  06850000
      *    MOVE TI-TR02-APE-MAT-CLI-ORIG   TO TI-CF06-APE-MAT-CLI-ORIG  06860000
      *    MOVE TI-TR02-NOMBRE-CLI-ORIG    TO TI-CF06-NOMBRE-CLI-ORIG   06870000
      *    MOVE TI-TR02-DIRECC-CLI-ORIG    TO TI-CF06-DIRECC-CLI-ORIG   06880000
      *    MOVE TI-TR02-NRO-CEL-CLI-ORIG   TO TI-CF06-NRO-CEL-CLI-ORIG  06890000
      *    MOVE TI-TR02-ENTIDAD-DESTINO    TO TI-CF06-ENTIDAD-DESTINO   06900000
      *    MOVE TI-TR02-CCI-CLI-BENEFICIA  TO TI-CF06-CCI-CLI-BENEFICIA 06910000
      *    MOVE TI-TR02-COD-TARJETA-CRED   TO TI-CF06-COD-TARJETA-CRED  06920000
      *    MOVE SPACES                     TO TI-CF06-IDC-BEN           09600000
      *    MOVE TI-TR02-TIP-DOC-CLI-BENE   TO TI-CF06-TIP-DOC-CLI-BENE  06940000
      *    MOVE TI-TR02-NRO-DOC-CLI-BENE   TO TI-CF06-NRO-DOC-CLI-BENE  06950000
      *    MOVE SPACES                     TO TI-CF06-APE-PAT-CLI-BENE  06960000
      *    MOVE SPACES                     TO TI-CF06-APE-MAT-CLI-BENE  06970000
      *    MOVE SPACES                     TO TI-CF06-NOMBRE-CLI-BENE   06980000
      *    MOVE TI-TR02-DIRECC-CLI-BENE    TO TI-CF06-DIRECC-CLI-BENE   06990000
      *    MOVE TI-TR02-TELEF-CLI-BENE     TO TI-CF06-TELEF-CLI-BENE    07000000
      *    MOVE TI-TR02-NRO-CEL-CLI-BENE   TO TI-CF06-NRO-CEL-CLI-BENE  07010000
      *    MOVE TI-TR02-INDI-MISMO-CLIENTE TO TI-CF06-INDI-MISMO-CLIENTE07020000
      *    MOVE '000'                      TO TI-CF06-SUCURSAL-ORIG-OPE 00069579
      *    MOVE '000'                      TO TI-CF06-AGENCIA-ORIG-OPE  00069579
      *    .                                                            09700100
      ************************ FIN DE 4200-LLENA-RECORD-TRANF           09701000
      *GNS-F                                                                    
      *GNS-I                                                                    
      **************                                                    11530000
      *5000-REENVIO.                                                    11540000
      **************                                                    11541000
      ***************************************************************** 11550000
      * VERIFICAR SI REGISTRO EXISTE EN MAESTRO DE TRX                  11560000
      ***************************************************************** 11570000
      **   ASIGNAMOS VALORES A KEY                                      11580000
      *                                                                 00084358
      *    PERFORM 5050-GESTIONAR-SEMAF-REINTENTO                       00084358
      *            UNTIL WS-ENQ-RESOURCE-SI                             00084358
      *                  OR WS-CONTADOR-ENQ > WS-CONTADOR-ENQ-MAX       00084358
      *                                                                 00084358
      *    SET  TI-CF06-88-COD-PROCESO-TRN TO TRUE                      11590000
      *    SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      11600000
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 11610000
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         11620000
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   11630000
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       11640000
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       11650000
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        11660000
      *                                                                 11670000
      **   EXEC CICS READ FILE   (TI-CW03-FILE-MAESTRO)                 00160022
      *    EXEC CICS READ FILE   (WS-FILE-NM-MAESTRO)                   00160022
      *         INTO             (TI-CF06-REG-TRANS)                    11690000
      *         LENGTH           (LENGTH OF TI-CF06-REG-TRANS)          11700000
      *         RIDFLD           (TI-CF06-REG-KEY-TRANS)                11710000
      *         KEYLENGTH        (LENGTH OF TI-CF06-REG-KEY-TRANS)      11720000
      *         RESP             (WS-RESP)                              11730000
      *    END-EXEC                                                     11740000
      *                                                                 11750000
      *    IF  WS-RESP = DFHRESP (NORMAL)                               11760000
      **       ACEPTADA / RECHAZADA                                     11770000
      *        IF  TI-CF06-ESTADO = WS-CT-00 OR                         11780000
      *            TI-CF06-ESTADO = WS-CT-02                            11790000
      *            IF  TI-CF06-ESTADO = WS-CT-02                        00160022
      *                AND TI-CF06-COD-RESP-AMPLIADO = WS-CT-1021       00160022
      *                PERFORM 5600-CONSULTA-PREVIA                     00160022
      *                MOVE TI-CF06-AUTORIZAT-ID-RESP                   00160022
      *                                    TO TI-TR02-AUTORIZAT-ID-RESP 00160022
      *                PERFORM 5500-PROCESA-TRANSFENCIA                 00160022
      *                                                                 00160022
      *            ELSE                                                 00160022
      *                MOVE TI-CF06-RESPONSE-CODE-CCE                   11800000
      *                                    TO TI-TR02-RESPONSE-CODE-CCE 11800100
      *                MOVE TI-CF06-COD-RESP-AMPLIADO                   11801000
      *                                    TO TI-TR02-COD-RESP-AMPLIADO 11801100
      *                MOVE TI-CF06-ORIGEN-RESPUESTA                    11802000
      *                                    TO TI-TR02-ORIGEN-RESPUESTA  11802100
      *                MOVE TI-CF06-MENSAJE-RESPUESTA                   11803000
      *                                    TO TI-TR02-MENSAJE-RESPUESTA 11804000
      *                MOVE TI-CF06-AUTORIZAT-ID-RESP                   11805000
      *                                    TO TI-TR02-AUTORIZAT-ID-RESP 11806000
      *                                                                 00160022
      *            END-IF                                               00160022
      *        ELSE                                                     11810000
      **       PENDIENTE                                                11820000
      *            PERFORM 5600-CONSULTA-PREVIA                         11830000
      *            MOVE TI-CF06-AUTORIZAT-ID-RESP                       00160022
      *                                    TO TI-TR02-AUTORIZAT-ID-RESP 00160022
      *            PERFORM 5500-PROCESA-TRANSFENCIA                     11850000
      *        END-IF                                                   11860000
      *    ELSE                                                         11870000
      **       REENVIO SIN REG-MAESTRO-TRANSF.                          11880000
      *        PERFORM 5600-CONSULTA-PREVIA                             11881000
      *        PERFORM 5200-ASIGNA-DATOS-REENVIO                        11890000
      *        PERFORM 5100-GRABAR-ACTUALIZACION                        11900000
      *        PERFORM 5500-PROCESA-TRANSFENCIA                         11910000
      *    END-IF                                                       11920000
      *    .                                                            11921000
      ************************ FIN DE 5000-REENVIO                      11922000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *******************************                                   00084358
       5000-CONFIRMACION-CANCELACION.                                   08100000
      *******************************                                   00084358
      ***************************************************************** 08460000
      * ASIGNA A COPY MAESTRO DE TRANSFERENCIAS E INVOCA CONSULTA       08470000
      ***************************************************************** 08480000
                                                                        08481000
           PERFORM 4100-TRANSFERENCIA-PREVIA                            08490000
           PERFORM 4050-GESTIONAR-SEMAF-PROC-NOR                        00084358
           PERFORM 5700-PROCESA-CONFIR-CANCEL                           08510000
           .                                                            08510100
      ************************ FIN DE 5000-CONFIRMACION-CANCELACION     08511000
      *GNS-F                                                                    
      *GNS-I                                                                    
      ********************************                                  00084358
      *5050-GESTIONAR-SEMAF-REINTENTO.                                  00084358
      ********************************                                  00084358
      ******************************************************************00084358
      * REALIZA INICIO Y EVALUA USO DE SEMAFORO PARA TRANSFERENCIA     *00084358
      * DE PROCESO NORMAL                                              *00084358
      ******************************************************************00084358
      *                                                                 00084358
      *    MOVE SPACES                     TO TI-CF06-REG-KEY-TRANS     00084358
      *                                                                 00084358
      *    SET  TI-CF06-88-COD-PROCESO-TRN TO TRUE                      00084358
      *    SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      00084358
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 00084358
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         00084358
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   00084358
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       00084358
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       00084358
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        00084358
      *                                                                 00084358
      *    MOVE TI-CF06-REG-KEY-TRANS      TO WS-RESOURCE-KEY-TRANSF    00084358
      *                                                                 00084358
      *    EXEC CICS ENQ                                                00084358
      *         RESOURCE(WS-RESOURCE)                                   00084358
      *         LENGTH(48)                                              00084358
      *         NOSUSPEND                                               00084358
      *         RESP(WS-RESP)                                           00084358
      *    END-EXEC                                                     00084358
      *                                                                 00084358
      *    EVALUATE WS-RESP                                             00084358
      *        WHEN DFHRESP(NORMAL)                                     00084358
      *            SET  WS-ENQ-RESOURCE-SI TO TRUE                      00084358
      *                                                                 00084358
      *        WHEN OTHER                                               00084358
      *            EXEC CICS DELAY INTERVAL(02)                         00084358
      *            END-EXEC                                             00084358
      *                                                                 00084358
      *            COMPUTE WS-CONTADOR-ENQ = WS-CONTADOR-ENQ + 1        00084358
      *                                                                 00084358
      *    END-EVALUATE                                                 00084358
      *    .                                                            00084358
      ************************ FIN DE 5050-GESTIONAR-SEMAF-REINTENTO    00084358
      *GNS-F                                                                    
      *GNS-I                                                                    
      ***************************                                       11930000
      *5100-GRABAR-ACTUALIZACION.                                       11940000
      ***************************                                       11941000
      ******************************************************************11950000
      * GRABA LA RPTA FINAL EN EL ARCHIVO MAESTRO DE TRANSACCIONES     *11960000
      ******************************************************************11961000
      *                                                                 11962000
      **   EXEC CICS WRITE   FILE (TI-CW03-FILE-MAESTRO)                00160022
      *    EXEC CICS WRITE   FILE (WS-FILE-NM-MAESTRO)                  00160022
      *                      FROM (TI-CF06-REG-TRANS)                   11990000
      *                    LENGTH (LENGTH OF TI-CF06-REG-TRANS)         12000000
      *                    RIDFLD (TI-CF06-REG-KEY-TRANS)               12010000
      *                 KEYLENGTH (LENGTH OF TI-CF06-REG-KEY-TRANS)     12020000
      *                      RESP (WS-RESP)                             12030000
      *    END-EXEC                                                     12040000
      *                                                                 12050000
      *    EVALUATE WS-RESP                                             12060000
      *        WHEN DFHRESP(NORMAL)                                     12070000
      *             CONTINUE                                            12080000
      *        WHEN OTHER                                               12090000
      **           OBTENER MENSAJE PARA CCE                             12100000
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  12110000
      *                                                                 12120000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  12130000
      *            SET  TI-CF06-88-RECH        TO TRUE                  12140000
      *            MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 12140100
      *                                       WS-TEMP-XX                12140200
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12140300
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 12140400
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12140500
      *            MOVE WS-CT-1021         TO WS-CT-NUMER               12140600
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *            MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  12140700
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         12140800
      *                                                                 12140900
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 12141000
      *            PERFORM 6300-ACTUALIZA-COMAREA                       12141100
      *                                                                 12141200
      **           OBTENER MENSAJE INTERNO                              12141300
      *            MOVE SPACES             TO TI-CA15-I-O-MENSAJES      12141400
      *            SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  12141500
      *            MOVE 'TI0807'           TO TI-CF06-CODMSG-ESTRUCT    12141600
      *                                       WS-CODMSG-ESTRUCTURA      12141700
      *                                       WS-COD-ERROR-07           12141800
      *            MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            12141900
      *                                       WS-PROGRAM                12142000
      *            MOVE TI-CW03-FILE-MAESTRO                            00160022
      *            MOVE WS-FILE-NM-MAESTRO                              00160022
      *                                    TO WS-VARMSG-RSO             12142200
      *            MOVE WS-RESP            TO WS-VARMSG-ARG             12142300
      *                                                                 12142400
      *            PERFORM 6100-OBTENER-MENSAJE                         12142500
      *            MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        12142600
      *                                                                 12142700
      *                                                                 12142800
      *            PERFORM 6200-GRABAR-LOG-EVENTOS                      12142900
      *            PERFORM 6000-FINAL                                   12143000
      *    END-EVALUATE                                                 12143100
      *    .                                                            12144000
      ************************ FIN DE 5100-GRABAR-ACTUALIZACION         12150000
      *GNS-F                                                                    
      *GNS-I                                                                    
      ***************************                                       12150100
      *5200-ASIGNA-DATOS-REENVIO.                                       12150200
      ***************************                                       12150300
      ****************************************************************  12150400
      * ASIGNA DATOS A COPY MAESTRO DE TRANSFERENCIAS                   12150500
      ****************************************************************  12150600
      *                                                                 12150700
      *    SET  TI-CF06-88-COD-PROCESO-TRN  TO TRUE                     12150800
      *    SET  TI-CF06-88-TIPO-ROL-RECEPT  TO TRUE                     12150900
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE   TO TI-CF06-TRACE-ADQUIRIENTE12151000
      *    MOVE TI-TR02-CANAL               TO TI-CF06-CANAL-CCE        12151100
      *    MOVE TI-TR02-BIN-ADQUIRIENTE     TO TI-CF06-BIN-ADQUIRIENTE  12151200
      *    MOVE TI-TR02-TERMINAL-ID         TO TI-CF06-TERMINAL-ID      12151300
      *    MOVE TI-TR02-DATE-LOCAL          TO TI-CF06-FECHA-TRANS      12151400
      *    MOVE TI-TR02-TIME-LOCAL          TO TI-CF06-HORA-TRANS       12151500
      *    MOVE WS-FECHA-INI                TO TI-CF06-FECHA-PROCESO    12151600
      *    MOVE WS-HORA-INI                 TO TI-CF06-HORA-PROCESO     12151700
      *    MOVE TI-TR02-ENTIDAD-ORIGEN(2:3) TO TI-CF06-CODIGO-BCO-EMI   12151800
                                                                                
      *    MOVE WS-CT-TI                    TO TI-CF06-CANAL-BCP        12151900
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE   TO TI-CF06-NRO-OPERACION-CNL12152000
      *    SET TI-CF06-88-PEND              TO TRUE                     12152100
      *    SET TI-CF06-88-SI-REENV          TO TRUE                     12152200
      *    MOVE SPACES                      TO TI-CF06-NUM-LIQ-I        12152300
      *    MOVE TI-TR02-TIPO-PROCESO        TO TI-CF06-TIPO-PROCESO     12152400
      *    MOVE TI-TR02-FECHA-HORA-PROC     TO TI-CF06-FECHA-PROCESO-CCE12152500
      *    MOVE TI-TR02-NRO-REFERENCIA      TO TI-CF06-NRO-REFERENCIA   12152600
      **                                                                12152700
      **   INCLUIR RUTINA PARA OBTENER NUMERO DE OPERACION              12152800
      *    MOVE WS-NRO-OPER-COUNTER         TO WS-NRO-OPER-COUNTER-TMP  12153100
      *    MOVE WS-NRO-OPER-COUNTER-TMP     TO TI-TR02-AUTORIZAT-ID-RESP12153200
      *    MOVE TI-TR02-AUTORIZAT-ID-RESP   TO TI-CF06-AUTORIZAT-ID-RESP12153300
      *    MOVE TI-TR02-AUTORIZAT-ID-RESP   TO TI-CF06-AUTORIZAT-ID-RESP12153400
      *    MOVE SPACES                      TO TI-CF06-RESPONSE-CODE-CCE12153500
      *    MOVE TI-TR02-COMERCIO            TO TI-CF06-COMERCIO         12153600
      *    MOVE TI-TR02-CARD-ACEPTOR-LOCA   TO TI-CF06-CARD-ACEPTOR-LOCA12153700
      *    MOVE SPACES                      TO TI-CF06-COD-RESP-AMPLIADO12153800
      *    MOVE SPACES                      TO TI-CF06-ORIGEN-RESPUESTA 12153900
      *    MOVE SPACES                      TO TI-CF06-MENSAJE-RESPUESTA12154000
      *    MOVE TI-TR02-RUTEO               TO TI-CF06-ENT-BEN          12154100
      *    MOVE TI-TR02-COD-APLICACION      TO TI-CF06-COD-APLICACION   12154200
      *    MOVE TI-TR02-TIPO-SESION         TO TI-CF06-TIPO-SESION      12154300
      *    PERFORM 5300-BUSCAR-MON                                      12154400
      *    PERFORM 5400-BUSCAR-CAUSAL                                   12154500
      *    MOVE SPACES                      TO TI-CF06-TIP-PAGO         12154600
      *    MOVE TI-TR02-IMPORTE             TO WS-TR02-IMPORTE-R        12154700
      *    COMPUTE WS-TR02-IMPORTE-R = WS-TR02-IMPORTE-R / 100          12154800
      *    END-COMPUTE                                                  12154900
      *    MOVE WS-TR02-IMPORTE-R           TO TI-CF06-IMPORTE          12155000
      *    MOVE TI-TR02-ID-TRANS-CCE-ONLINE TO                          12155300
      *                                     TI-CF06-ID-TRANS-CCE-ONLINE 12155400
      *    MOVE TI-TR02-ID-TRANS-CCE-ONL-OR TO                          12155500
      *                                     TI-CF06-ID-TRANS-CCE-ONL-ORG12155600
      *    MOVE TI-TR02-ID-SESION-APLICA    TO TI-CF06-ID-SESION-APLICA 12155700
      *    MOVE TI-TR02-CONCEPT-COBRO-TARI  TO                          12155800
      *                                     TI-CF06-CONCEPT-COBRO-TARI  12155900
      *    MOVE TI-TR02-CODIGO-TARIFA       TO TI-CF06-CODIGO-TARIFA    12156000
      *    MOVE ZEROS                       TO TI-CF06-IMPORTE-COMISION 12156100
      *    MOVE TI-TR02-IMPORTE-COMISION    TO WS-TR02-IMPORTE-COMI-R   12156200
      **                                                                12156300
      *    COMPUTE WS-TR02-IMPORTE-COMI-R = WS-TR02-IMPORTE-COMI-R / 10012156400
      *    END-COMPUTE                                                  12156500
      **                                                                12156600
      *    IF TI-TR02-SIGNO-COMISION = '-'                              12156700
      *       COMPUTE TI-CF06-IMP-COM-INTERB =                          12156800
      *               WS-TR02-IMPORTE-COMI-R   * -1                     12156900
      *       END-COMPUTE                                               12157000
      *    ELSE                                                         12157100
      *       MOVE WS-TR02-IMPORTE-COMI-R   TO TI-CF06-IMP-COM-INTERB   12157200
      *    END-IF                                                       12157300
      *    MOVE ZEROS                       TO TI-CF06-IMP-TOT          12157400
      *    MOVE TI-TR02-CRITERIO-APLICACION TO TI-CF06-CRITERIO-APLICA  12157500
      *    MOVE TI-TR02-REF-TRANSFERENCIA   TO TI-CF06-REF-TRANSFERENCIA12157600
      *    MOVE TI-TR02-INDICADOR-PAG-HAB   TO TI-CF06-INDICADOR-PAG-HAB12157700
      *    MOVE TI-TR02-MES-PAGO            TO TI-CF06-MES-PAGO         12157800
      *    MOVE TI-TR02-ANIO-PAGO           TO TI-CF06-ANIO-PAGO        12157900
      *    MOVE TI-TR02-IMPORT-SUELDO-BRUTO TO                          12158000
      *                                     TI-CF06-IMPORT-SUELDO-BRUTO 12158100
      *    MOVE TI-TR02-NRO-CORTE           TO TI-CF06-NRO-CORTE        12158200
      *    MOVE TI-TR02-ID-ALERTA           TO TI-CF06-ID-ALERTA        12158300
      *    MOVE TI-TR02-ENTIDAD-ORIGEN      TO TI-CF06-ENTIDAD-ORIGEN   12158400
      *    MOVE TI-TR02-CCI-CLI-ORIGINANTE  TO TI-CF06-CCI-CLI-ORIG     12158500
      *    MOVE TI-TR02-TIPO-PERSONA        TO TI-CF06-TIPO-PERSONA     12158600
      *    MOVE SPACES                      TO TI-CF06-IDC-ORI          12158700
      *    MOVE TI-TR02-TIP-DOC-CLI-ORIG    TO TI-CF06-TIP-DOC-CLI-ORIG 12158800
      *    MOVE TI-TR02-NRO-DOC-CLI-ORIG    TO TI-CF06-NRO-DOC-CLI-ORIG 12158900
      *    MOVE TI-TR02-APE-PAT-CLI-ORIG    TO TI-CF06-APE-PAT-CLI-ORIG 12159000
      *    MOVE TI-TR02-APE-MAT-CLI-ORIG    TO TI-CF06-APE-MAT-CLI-ORIG 12159100
      *    MOVE TI-TR02-NOMBRE-CLI-ORIG     TO TI-CF06-NOMBRE-CLI-ORIG  12159200
      *    MOVE TI-TR02-DIRECC-CLI-ORIG     TO TI-CF06-DIRECC-CLI-ORIG  12159300
      *    MOVE TI-TR02-NRO-CEL-CLI-ORIG    TO TI-CF06-NRO-CEL-CLI-ORIG 12159400
      *    MOVE TI-TR02-ENTIDAD-DESTINO     TO TI-CF06-ENTIDAD-DESTINO  12159500
      *    MOVE TI-TR02-CCI-CLI-BENEFICIA   TO TI-CF06-CCI-CLI-BENEFICIA12159600
      *    MOVE TI-TR02-COD-TARJETA-CRED    TO TI-CF06-COD-TARJETA-CRED 12159700
      *    MOVE SPACES                      TO TI-CF06-IDC-BEN          12159800
      *    MOVE TI-TR02-TIP-DOC-CLI-BENE    TO TI-CF06-TIP-DOC-CLI-BENE 12159900
      *    MOVE TI-TR02-NRO-DOC-CLI-BENE    TO TI-CF06-NRO-DOC-CLI-BENE 12160000
      *    MOVE TI-TR02-APE-PAT-CLI-BENE    TO TI-CF06-APE-PAT-CLI-BENE 12160400
      *    MOVE TI-TR02-APE-MAT-CLI-BENE    TO TI-CF06-APE-MAT-CLI-BENE 12160500
      *    MOVE TI-TR02-NOMBRE-CLI-BENE     TO TI-CF06-NOMBRE-CLI-BENE  12160600
      *    MOVE TI-TR02-DIRECC-CLI-BENE     TO TI-CF06-DIRECC-CLI-BENE  12160700
      *    MOVE TI-TR02-TELEF-CLI-BENE      TO TI-CF06-TELEF-CLI-BENE   12160800
      *    MOVE TI-TR02-NRO-CEL-CLI-BENE    TO TI-CF06-NRO-CEL-CLI-BENE 12160900
      *                                                                 12161000
      **   MOVE SPACES                      TO                          00076344
      *    MOVE TI-TR02-INDI-MISMO-CLIENTE  TO                          00076344
      *                                     TI-CF06-INDI-MISMO-CLIENTE  12161200
      *    .                                                            12161300
      ************************ FIN DE 5200-ASIGNA-DATOS-REENVIO         12161400
      *GNS-F                                                                    
      *GNS-I                                                                    
      *****************                                                 12161500
      *5300-BUSCAR-MON.                                                 12161600
      *****************                                                 12161700
      *    MOVE SPACES     TO TI-CF01-KEY03                             12161800
      *    MOVE WS-CT-03   TO TI-CF01-KEY03-TIP-PRM                     12161900
      *    MOVE WS-CT-10C  TO TI-CF01-KEY03-CTABL                       12162000
      *    MOVE TI-TR02-TRANS-CURREN-CODE                                       
      *                    TO TI-CF01-KEY03-DTABL                       12162200
      *                                                                 12162300
      *    EXEC CICS READ    FILE (TI-CW03-FILE-PARAMETROS)             12162400
      *                      INTO (TI-CF01-REG-PARAMETROS)              12162500
      *                    LENGTH (LENGTH OF TI-CF01-REG-PARAMETROS)    12162600
      *                    RIDFLD (TI-CF01-KEY03)                       12162700
      *                 KEYLENGTH (LENGTH OF TI-CF01-KEY03)             12162800
      *                      RESP (WS-RESP)                             12162900
      *    END-EXEC                                                     12163000
      *                                                                 12163100
      *    IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        12163200
      *        MOVE WS-RESP                TO WS-RESP-TXT               00160022
      **       OBTENER MENSAJE PARA CCE                                 12163300
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12163400
      *                                                                 12163500
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      12163600
      *        SET  TI-CF06-88-RECH        TO TRUE                      12163700
      *        MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 12163800
      *                                       WS-TEMP-XX                12163900
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12164000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *        MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 12164100
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12164200
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               12164300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *        MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  12164400
      *        PERFORM 6300-ACTUALIZA-COMAREA                           12164800
      *                                                                 12164900
      **       OBTENER MENSAJE INTERNO                                  12165000
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12165100
      *        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      12165200
      *        MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    12165300
      *                                       WS-CODMSG-ESTRUCTURA      12165400
      *                                       WS-COD-ERROR-07           12165500
      *        MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            12165600
      *                                       WS-PROGRAM                12165700
      *        MOVE TI-CW03-FILE-PARAMETROS                             12165800
      *                                    TO WS-VARMSG-RSO             12165900
      *        MOVE WS-RESP                TO WS-VARMSG-ARG             12166000
      *                                                                 12166100
      *        PERFORM 6100-OBTENER-MENSAJE                             12166200
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            12166300
      *                                                                 12166400
      *                                                                 12166500
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          12166600
      *        PERFORM 6000-FINAL                                       12166700
      *    ELSE                                                         12166800
      *        MOVE TI-CF01-DTBL-VALOR(1:4)    TO TI-CF06-COD-MON       12166900
      *    END-IF                                                       12167000
      *    .                                                            12167100
      ************************ FIN DE 5300-BUSCAR-MON                   12167200
      *GNS-F                                                                    
      *GNS-I                                                                    
      ********************                                              12167300
      *5400-BUSCAR-CAUSAL.                                              12167400
      ********************                                              12167500
      *                                                                 12167600
      *    MOVE SPACES                     TO TI-CF01-KEY05             12167700
      *    MOVE WS-CT-05                   TO TI-CF01-KEY05-TIP-PRM     12167800
      *    MOVE SPACES                     TO TI-CF01-KEY05-TIP-TRANS   12167900
      *    SET  TI-CA80-88-MPARAMETROS         TO TRUE                  12168000
      *    MOVE TI-CF01-REG-PARAMETROS         TO TI-CA80-I-REG-MPARAM  12169000
      *    SET  TI-CA80-I-88-TACC-CONSULTAR    TO TRUE                  12170000
      *    SET  TI-CA80-I-TCONS-MASIVA         TO TRUE                  12171000
      *                                                                 12171100
      *    EXEC CICS LINK PROGRAM (TI-CW03-PGM-PARAMETROS)              12171200
      *                   COMMAREA(TI-CA80-COMMAREA)                    12171300
      *                   LENGTH  (LENGTH OF TI-CA80-COMMAREA)          12171400
      *                   RESP (WS-RESP)                                12171500
      *    END-EXEC                                                     12171600
      *                                                                 12171700
      *    EVALUATE WS-RESP                                             12171800
      *        WHEN DFHRESP(NORMAL)                                     12171900
      *            IF  TI-CA80-O-RC-NRO NOT = ZEROS                     12172000
      **               OBTENER MENSAJE PARA CCE                         12172100
      *                MOVE SPACES             TO TI-CA15-I-O-MENSAJES          
      *                                                                         
      *                SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      
      *                SET  TI-CF06-88-RECH        TO TRUE              12172500
      *                MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 12172600
      *                                       WS-TEMP-XX                12172700
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)        
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *                MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 12172900
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12173000
      *                MOVE WS-CT-1021     TO WS-CT-NUMER               12173100
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *                MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  12173200
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *                PERFORM 6100-OBTENER-MENSAJE                     12173300
      *                                                                 12173400
      *                MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 12173500
      *                                                                 12173600
      **               OBTENER MENSAJE INTERNO                          12173700
      *                MOVE TI-CA80-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT12173800
      *                                           WS-COD-ERROR-07       12173900
      *                MOVE TI-CW03-PGM-PARAMETROS                      12174000
      *                                        TO TI-CF06-PRGNOM        12174100
      *                                           WS-PROGRAM            12174200
      *                MOVE TI-CA80-O-RC-MSG   TO TI-CF06-TXTMSG        12174300
      *                                           WS-MENSAJE-TXT-EVE    12174400
      *                                                                 12174500
      *                PERFORM 6300-ACTUALIZA-COMAREA                   12174600
      *                PERFORM 6200-GRABAR-LOG-EVENTOS                  12174700
      *                PERFORM 6000-FINAL                               12174800
      *            END-IF                                               12174900
      *        WHEN OTHER                                               12175000
      **           OBTENER MENSAJE PARA CCE                             12175100
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  12175200
      *                                                                 12175300
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  12175400
      *            SET  TI-CF06-88-RECH        TO TRUE                  12175500
      *            MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 12175600
      *                                       WS-TEMP-XX                12175700
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12175800
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 12175900
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12176000
      *            MOVE WS-CT-1021         TO WS-CT-NUMER               12176100
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *            MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  12176200
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         12176300
      *                                                                 12176400
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 12176500
      *            PERFORM 6300-ACTUALIZA-COMAREA                       12176600
      *                                                                 12176700
      **           OBTENER MENSAJE INTERNO                              12176800
      *            MOVE SPACES             TO TI-CA15-I-O-MENSAJES      12176900
      *            SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  12177000
      *            MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT12177100
      *                                       WS-CODMSG-ESTRUCTURA      12177200
      *                                       WS-COD-ERROR-07           12177300
      *            MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM        12177400
      *                                           WS-PROGRAM            12177500
      *            MOVE 'LINK'                 TO WS-VARMSG-FUN         12177600
      *            MOVE TI-CW03-PGM-PARAMETROS TO WS-VARMSG-RSO         12177700
      *                                                                 12177800
      *            PERFORM 6100-OBTENER-MENSAJE                         12177900
      *            MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        12178000
      *                                                                 12178100
      *                                                                 12178200
      *            PERFORM 6200-GRABAR-LOG-EVENTOS                      12178300
      *            PERFORM 6000-FINAL                                   12178400
      *    END-EVALUATE                                                 12178500
      *                                                                 12178600
      *    MOVE 1 TO WS-I                                               12178700
      *    MOVE TI-CA80-O-REG-PARAM(WS-I)  TO TI-CF01-REG-PARAMETROS    12178800
      *                                                                 12178900
      *    PERFORM UNTIL WS-I > TI-CA80-O-NRO-REGISTROS                 12179000
      *      MOVE TI-CA80-O-REG-PARAM(WS-I)    TO TI-CF01-REG-PARAMETROS12179100
      *      IF  TI-CF01-TRAN-COD-CCE EQUAL TI-TR02-TRANS-EXTENDIDA             
      *          MOVE TI-CF01-KEY05-TIP-TRANS   TO TI-CF06-CAUSAL       12179300
      *          MOVE TI-CA80-O-NRO-REGISTROS   TO WS-I                 12179400
      *                                                                 12179500
      *      END-IF                                                     12179600
      *      COMPUTE WS-I = WS-I + 1                                    12179700
      *                                                                 12179800
      *    END-PERFORM                                                  12179900
      *    .                                                            12180000
      ************************ FIN DE 5400-BUSCAR-CAUSAL                12181000
      *GNS-F                                                                    
      **************************                                        12185700
      *GNS-I                                                                    
      *5500-PROCESA-TRANSFENCIA.                                        12185800
       5700-PROCESA-CONFIR-CANCEL.                                      12185800
      *GNS-F                                                                    
      **************************                                        12185900
                                                                        12186000
      *GNS-I                                                                    
      *    MOVE TI-TR02-I-TRAMA            TO TI-CA02-REG-TRANS-DATA    00160022
           MOVE TI-TRR2-I-TRAMA            TO TI-CAR2-REG-TRANS-DATA    00160022
      *GNS-F                                                                    
                                                                        00160022
      *    EXEC CICS LINK PROGRAM(WS-PROG-TRANSFERENCIA)                00160022
      *                  COMMAREA(TI-TR02-I-TRAMA)                      00160022
      *                    LENGTH(LENGTH OF TI-TR02-I-TRAMA)            00160022
      *                      RESP(WS-RESP)                              00160022
      *    END-EXEC                                                     00160022
                                                                        12186600
      *GNS-I                                                                    
      *    EXEC CICS LINK PROGRAM(WS-PROG-TRANSFERENCIA)                12186100
           EXEC CICS LINK PROGRAM(WS-PROG-CONFIRMACION)                 12186100
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                  COMMAREA(TI-CA02-AREA-COMUNICACION)            00160022
      *                    LENGTH(LENGTH OF TI-CA02-AREA-COMUNICACION)  00160022
                         COMMAREA(TI-CAR2-AREA-COMUNICACION)            00160022
                           LENGTH(LENGTH OF TI-CAR2-AREA-COMUNICACION)  00160022
      *GNS-F                                                                    
                             RESP(WS-RESP)                              12186400
           END-EXEC                                                     12186500
                                                                        12186600
           IF  WS-RESP EQUAL TO DFHRESP(NORMAL)                         12186700
      *GNS-I                                                                    
      *        MOVE TI-CA02-REG-TRANS-DATA     TO TI-TR02-I-TRAMA       00160022
      *        MOVE TI-TR02-I-TRAMA            TO DFHCOMMAREA           12186800
               MOVE TI-CAR2-REG-TRANS-DATA     TO TI-TRR2-I-TRAMA       00160022
               MOVE TI-TRR2-I-TRAMA            TO DFHCOMMAREA           12186800
      *GNS-F                                                                    
               CONTINUE                                                 12186900
           ELSE                                                         12187000
      *GNS-I                                                                    
               PERFORM 1620-ACTUALIZA-COMAREA                           00160022
      *GNS-F                                                                    
      *        OBTENER MENSAJE PARA CCE                                 12187600
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12187700
      *                                                                 12187800
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      12187900
      *GNS-F                                                                    
               SET  TI-CF06-88-RECH        TO TRUE                      12188000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 12188100
                                              WS-TEMP-XX                12188200
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12188300
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 12188400
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12188500
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               12188600
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX                      
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  12188700
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             12188800
      *                                                                 12188900
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 12189000
      *GNS-F                                                                    
               PERFORM 6300-ACTUALIZA-COMAREA                           12189100
                                                                        12189200
      *        OBTENER MENSAJE INTERNO                                  12189300
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12189400
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      12189500
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    12189600
                                              WS-CODMSG-ESTRUCTURA      12189700
                                              WS-COD-ERROR-07           12189800
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            12189900
                                              WS-PROGRAM                12190000
               MOVE 'LINK'                 TO WS-VARMSG-FUN             12190100
      *GNS-I                                                                    
      *        MOVE WS-PROG-CONSULTA       TO WS-VARMSG-RSO             12190200
               MOVE WS-PROG-CONFIRMACION   TO WS-VARMSG-RSO             12190200
      *GNS-F                                                                    
                                                                        12190300
               PERFORM 6100-OBTENER-MENSAJE                             12190400
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            12190500
      *GNS-I                                                                    
                                              WS-MENSAJE-TXT-EVE        00160022
      *GNS-F                                                                    
                                                                        12190600
                                                                        12190700
               PERFORM 6200-GRABAR-LOG-EVENTOS                          12190800
               PERFORM 6000-FINAL                                       12190900
                                                                        12191000
           END-IF                                                       12191100
           .                                                            12191200
      ************************ FIN DE 5700-PROCESA-CONFIR-CANCEL        12191300
      *GNS-I                                                                    
      **********************                                            12191400
      *5600-CONSULTA-PREVIA.                                            12191500
      **********************                                            12191600
      ****************************************************************  12191700
      * ASIGNA DATOS A COPY MAESTRO DE TRANSFERENCIAS                   12191800
      ****************************************************************  12191900
      *                                                                 12192000
      *    MOVE TI-TR02-ID-TRANS-CCE-ONL-OR                             12192100
      *                                TO TI-CF06-ID-TRANS-CCE-ONLINE   12192200
      *                                                                 12192300
      **   EXEC CICS READ   FILE (TI-CW03-FILE-MAESTRO-ALT2)            00160022
      *    EXEC CICS READ   FILE (WS-FILE-NM-MAESTRO-ALT2)              00160022
      *                     INTO (TI-CF06-REG-TRANS)                    12192500
      *                   LENGTH (LENGTH OF TI-CF06-REG-TRANS)          12192600
      *                   RIDFLD (TI-CF06-ID-TRANS-CCE-ONLINE)          12192700
      *                KEYLENGTH (LENGTH OF TI-CF06-ID-TRANS-CCE-ONLINE)12192800
      *                     RESP (WS-RESP)                              12192900
      *    END-EXEC                                                     12193000
      **                                                                12193100
      *    IF  WS-RESP = DFHRESP (NORMAL)                               12193200
      *        MOVE TI-CF06-INDI-MISMO-CLIENTE                          12193300
      *                                    TO TI-TR02-INDI-MISMO-CLIENTE12193400
      *        MOVE TI-CF06-APE-PAT-CLI-BENE                            12193500
      *                                    TO TI-TR02-APE-PAT-CLI-BENE  12193600
      *        MOVE TI-CF06-APE-MAT-CLI-BENE                            12193700
      *                                    TO TI-TR02-APE-MAT-CLI-BENE  12193800
      *        MOVE TI-CF06-NOMBRE-CLI-BENE                             12193900
      *                                    TO TI-TR02-NOMBRE-CLI-BENE   12194000
      *                                                                 12194100
      *    ELSE                                                         12194200
      *        MOVE WS-RESP                TO WS-RESP-TXT               12194300
      **       OBTENER MENSAJE PARA CCE                                 12194400
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12194500
      *                                                                 12194600
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      12194700
      *        SET  TI-CF06-88-RECH        TO TRUE                      12194800
      *        MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     12194900
      *                                   WS-TEMP-XX                    12195000
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    12195100
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *        MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     12195200
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    12195300
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   12195400
      *                                   TI-TR02-COD-RESP-AMPLIADO             
      *        MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      12195500
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             12195600
      *                                                                 12195700
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     12195800
      *        PERFORM 6300-ACTUALIZA-COMAREA                           12195900
      *                                                                 12196000
      **       OBTENER MENSAJE INTERNO                                  12196100
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12196200
      *        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      12196300
      *        MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    12196400
      *                                       WS-CODMSG-ESTRUCTURA      12196500
      *                                       WS-COD-ERROR-07           12196600
      *        MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            12196700
      *                                       WS-PROGRAM                12196800
      *        MOVE 'READ'                 TO WS-VARMSG-FUN             12196900
      **       MOVE TI-CW03-FILE-MAESTRO-ALT2                           00160022
      *        MOVE WS-FILE-NM-MAESTRO-ALT2                             00160022
      *                                    TO WS-VARMSG-RSO             12197100
      *        MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             12197200
      *                                                                 12197300
      *        PERFORM 6100-OBTENER-MENSAJE                             12197400
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            12197500
      *                                       WS-MENSAJE-TXT-EVE        12197600
      *                                                                 12197700
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          12197800
      *        PERFORM 6000-FINAL                                       12197900
      *    END-IF                                                       12198000
      *    .                                                            12198100
      ************************ FIN DE 5600-CONSULTA-PREVIA              12198200
      *GNS-F                                                                    
      ************                                                      12198300
       6000-FINAL.                                                      12198400
      ************                                                      12198500
      ******************************************************************12198600
      * FIN DEL PROCESO Y ENVIA MENSAJE AL OPERADOR                    *12198700
      ******************************************************************12199000
                                                                        12200000
      *GNS-I                                                                    
      *    IF  WS-SI-EXISTE-ERROR                                       12260100
      *        MOVE WS-COD-PROG          TO TI-CF06-PRGNOM              12260200
      *        MOVE WS-TXTMSG            TO TI-CF06-TXTMSG              12260300
      *        MOVE WS-CODMSG-ESTRUCTURA TO TI-CF06-CODMSG-ESTRUCT      12260400
      *    END-IF                                                       12260500
      *GNS-F                                                                    
                                                                        12260600
           IF  WS-ENQ-RESOURCE-SI                                       00084358
                                                                        00084358
               EXEC CICS DEQ                                            00084358
                    RESOURCE(WS-RESOURCE)                               00084358
                    LENGTH(48)                                          00084358
                    RESP(WS-RESP)                                       00084358
               END-EXEC                                                 00084358
                                                                        00084358
           END-IF                                                       00084358
                                                                        00084358
      *GNS-I                                                                    
      *    IF  TI-TR02-RESPONSE-CODE-CCE EQUAL SPACES                           
           IF  TI-TRR2-RESPONSE-CODE-CCE EQUAL SPACES                           
      *GNS-F                                                                    
                                               OR LOW-VALUES                    
                                               OR HIGH-VALUES                   
      *GNS-I                                                                    
      *        MOVE WS-CT-05               TO TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-05               TO TI-TRR2-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
           END-IF                                                               
      *GNS-I                                                                    
      *    IF  TI-TR02-COD-RESP-AMPLIADO EQUAL SPACES                           
           IF  TI-TRR2-COD-RESP-AMPLIADO EQUAL SPACES                           
      *GNS-F                                                                    
                                               OR LOW-VALUES                    
                                               OR HIGH-VALUES                   
      *GNS-I                                                                    
      *        MOVE WS-CT-1021             TO TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-1021             TO TI-TRR2-COD-RESP-AMPLIADO         
      *GNS-F                                                                    
           END-IF                                                               
      *GNS-I                                                                    
      *    IF  TI-TR02-ORIGEN-RESPUESTA  EQUAL SPACES                           
      *                                        OR LOW-VALUES                    
      *                                        OR HIGH-VALUES                   
      *        MOVE WS-CT-001              TO TI-TR02-ORIGEN-RESPUESTA          
      *    END-IF                                                       00084358
      *GNS-F                                                                    
                                                                        00084358
      *GNS-I                                                                    
      *    MOVE WS-CT-0210         TO TI-TR02-MSGE-TYPE-ID              12260700
      *GNS-F                                                                    
      *GNS-I                                                                    
JCS   *    MOVE SPACES             TO TI-TRR2-TERMINAL-ID               12260700
JCS   *                               TI-TRR2-NRO-REFERENCIA            12260700
JCS   *                               TI-TRR2-NOM-APE-ORIG              12260700
JCS   *                               TI-TRR2-NRO-DOC-CLI-ORIG          12260700
JCS   *                               TI-TRR2-TIP-DOC-CLI-ORIG          12260700
JCS   *                               TI-TRR2-TELEF-CLI-ORIG            12260700
JCS   *                               TI-TRR2-DIRECC-CLI-ORIG           12260700
JCS   *                               TI-TRR2-NRO-CEL-CLI-ORIG          12260700
JCS   *                               TI-TRR2-DIRECC-CLI-BENE           12260700
JCS   *                               TI-TRR2-TELEF-CLI-BENE            12260700
JCS   *                               TI-TRR2-NRO-CEL-CLI-BENE          12260700
JCS   *                               TI-TRR2-CCI-CLI-BENEFICIA         12260700
JCS   *                               TI-TRR2-COD-TARJETA-CRED          12260700
JCS   *                               TI-TRR2-TIPO-PERSONA              12260700
JCS   *                               TI-TRR2-NOM-APE-BENE              12260700
JCS   *                               TI-TRR2-NRO-DOC-CLI-BENE          12260700
JCS   *                               TI-TRR2-TIP-DOC-CLI-BENE          12260700
JCS   *                               TI-TRR2-INDI-MISMO-CLIENTE        12260700
JCS   *                               TI-TRR2-REF-TRANSFERENCIA         12260700
JCS   *                               TI-TRR2-REF-INSTRUCTION-ID        12260700
JCS   *                               TI-TRR2-CODIGO-TARIFA             12260700
JCS   *                               TI-TRR2-CRITERIO-APLICACION       12260700
JCS   *                               TI-TRR2-CCI-CLI-ORIGINANTE        12260700
JCS   *                               TI-TRR2-CONCEPT-COBRO             12260700
JCS   *                               TI-TRR2-GLOSA                     12260700
JCS   *                               TI-TRR2-INDICADOR-PAG-HAB         12260700
JCS   *                               TI-TRR2-MES-PAGO                  12260700
JCS   *                               TI-TRR2-ANIO-PAGO                 12260700
JCS   *                               TI-TRR2-PROXY-VALUE               12260700
JCS   *                               TI-TRR2-PROXY-TYPE                12260700
JCS   *    MOVE ZEROES             TO TI-TRR2-IMPORTE                   12260700
JCS   *                               TI-TRR2-IMPORTE-COMISION          12260700
JCS   *                               TI-TRR2-IMPORT-SUELDO-BRUTO       12260700
JCS   *                               TI-TRR2-FECHA-LIQUIDACION         12260700
JCS   *                               TI-TRR2-MONTO-LIQUIDACION         12260700
JCS   *    IF TI-CAR2-88-COD-PROCESO-CAN                                16491000
JCS   *        MOVE SPACES         TO TI-TRR2-ENTIDAD-ORIGEN            12260700
JCS   *                               TI-TRR2-TRANS-EXTENDIDA           12260700
JCS   *        MOVE ZEROES         TO TI-TRR2-CREATION-DATE             12260700
JCS   *                               TI-TRR2-CREATION-TIME             12260700
JCS   *                               TI-TRR2-TRACE-ADQUIRIENTE         12260700
JCS   *                               TI-TRR2-CANAL                     12260700
JCS   *    END-IF                                                       16491000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *    MOVE TI-TR02-I-TRAMA    TO DFHCOMMAREA                       12261000
           MOVE TI-TRR2-I-TRAMA    TO DFHCOMMAREA                       12261000
      *GNS-F                                                                    
                                                                        12262000
           EXEC CICS                                                    12270000
               RETURN                                                   12280000
           END-EXEC                                                     12290000
      *                                                                 12300000
           GOBACK                                                       12310000
           .                                                            12310100
      ************************ FIN DE 6000-FINAL                        12311000
      **********************                                            12332500
       6100-OBTENER-MENSAJE.                                            12332600
      **********************                                            12332700
      ******************************************************************12332800
      * MUEVE DATOS PARA LA RUTINA DE ARMADO DE MENSAJES               *12332900
      ******************************************************************12333000
                                                                        12333100
             MOVE WS-CODMSG-ESTRUCTURA       TO TI-CA15-I-RC-COD        12333200
             MOVE WS-PROGRAM-ID              TO TI-CA15-I-VAR-PROGRAMA  12333300
             MOVE WS-VARMSG-FUN              TO TI-CA15-I-VAR-FUNCION   12333400
             MOVE WS-VARMSG-RSO              TO TI-CA15-I-VAR-RECURSO   12333500
             MOVE WS-VARMSG-ARG              TO TI-CA15-I-VAR-ARGUMENTO 12333600
             MOVE WS-VARMSG-TXT              TO TI-CA15-I-VAR-TEXTO     12333700
             MOVE WS-RESP                    TO TI-CA15-I-EIBRESP       12333800
             MOVE WS-RESP2                   TO TI-CA15-I-EIBRESP2      12333900
      *GNS-I                                                                    
      *      MOVE TI-CW03-PGM-MENSAJES       TO WS-RTN-SGTE             12334000
             MOVE TI-CW04-PGM-MENSAJES       TO WS-RTN-SGTE             12334000
      *GNS-F                                                                    
             MOVE TI-CA15-I-O-MENSAJES       TO WS-CCAA                 12334100
             MOVE LENGTH OF TI-CA15-I-O-MENSAJES TO WS-LGTH-CCAA        12334200
                                                                        12334300
      *      NO SE UTILIZA EL LLAMADO AL LINK-GRAL PARA NO CAER EN BUCLE12334400
      *      SI EL PROGRAMA NO ESTA DISPONIBLE                          12334500
             EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                    12334600
                              COMMAREA (WS-CCAA)                        12334700
                                LENGTH (WS-LGTH-CCAA)                   12334800
                                  RESP (WS-RESP)                        12334900
                                 RESP2 (WS-RESP2)                       12335000
             END-EXEC                                                   12335100
                                                                        12335200
             IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                    12335300
      *GNS-I                                                                    
      *          STRING 'BCTITPR1' 'RUTINA' WS-RTN-SGTE                 12335400
                 STRING 'BCTITPR8' 'RUTINA' WS-RTN-SGTE                 12335400
      *GNS-F                                                                    
                 'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO      12335500
                 WS-TXTMSG                                              12335600
      *GNS-I                                                                    
                 END-STRING                                             12335400
                 SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE               05790000
                 MOVE WS-COD-E-LINK-GRAL         TO WS-CODMSG           05800000
                 MOVE WS-CODMSG-ESTRUCTURA       TO WS-CSMT-COD-RETORNO 05800000
                 MOVE WS-COD-PROG                TO WS-CSMT-COD-PROGRAMA05800000
                 MOVE WS-TXTMSG                  TO WS-CSMT-MENSAJE     05800000
                 PERFORM 6400-WRITE-CSMT                                00160022
                 PERFORM  6000-FINAL                                    12342200
      *GNS-F                                                                    
                                                                        12335700
             ELSE                                                       12335800
                 MOVE WS-CCAA                    TO TI-CA15-I-O-MENSAJES12335900
                 MOVE TI-CA15-O-RCODE            TO WS-CODMSG-ESTRUCTURA12336000
                 MOVE TI-CA15-O-RC-MSG           TO WS-TXTMSG           12336100
                                                    WS-MENSAJE-TXT      12336200
             END-IF                                                     12336300
             .                                                          12336400
      ************************ FIN DE 6100-OBTENER-MENSAJE              12336500
      *************************                                         12336600
       6200-GRABAR-LOG-EVENTOS.                                         12336700
      *************************                                         12336800
      *----------------------------------------------------------------*12336900
      * GRABAR MOTIVO DE ERROR EN EL LOG DE EVENTO                      12337000
      *----------------------------------------------------------------*12337100
           INITIALIZE  TI-CF07-REG-TRANS                                12337200
                       REPLACING  ALPHANUMERIC DATA BY SPACES           12337300
                                  NUMERIC DATA BY ZEROS                 12337400
      *GNS-I                                                                    
      *    IF  TI-TR02-MSGE-TYPE-ID   = WS-CT-0200                      12337500
      *        IF  TI-TR02-COD-PROCESO = WS-CT-800000                   12337600
      *            SET  TI-CF07-88-COD-PROCESO-CON TO TRUE              12337700
      *        END-IF                                                   12337800
      *        IF  TI-TR02-COD-PROCESO = WS-CT-490000                   12337900
      *            SET  TI-CF07-88-COD-PROCESO-TRN TO TRUE              12338000
      *        END-IF                                                   12338100
      *    END-IF                                                       12338200
      *                                                                 12338300
      *    IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201 AND                    12338400
      *        TI-TR02-COD-PROCESO  = WS-CT-490000                      12338500
      *        SET  TI-CF07-88-COD-PROCESO-TRN TO TRUE                  12338600
      *    END-IF                                                       12338700
           SET  TI-CF07-88-COD-PROCESO-TRN TO TRUE                      12337700
      *GNS-F                                                                    
                                                                        12338800
                                                                        12338900
           SET  TI-CF07-88-TIPO-ROL-RECEPT TO TRUE                      12339000
           MOVE TI-CF06-ESTADO             TO TI-CF07-ESTADO            12339100
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 12339200
      *    MOVE TI-TR02-CANAL              TO TI-CF07-CANAL-CCE         12339300
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF07-BIN-ADQUIRIENTE   12339400
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       12339500
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF07-FECHA-TRANS       12339600
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF07-HORA-TRANS        12339700
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 12339200
           MOVE TI-TRR2-CANAL              TO TI-CF07-CANAL-CCE         12339300
           MOVE SPACES                     TO TI-CF07-BIN-ADQUIRIENTE   12339400
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       12339500
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          12339600
           MOVE WS-DATE-LOCAL              TO TI-CF07-FECHA-TRANS       12339600
           MOVE TI-TRR2-CREATION-TIME      TO TI-CF07-HORA-TRANS        12339700
      *GNS-F                                                                    
           MOVE WS-COD-ERROR-07            TO TI-CF07-COD-ERROR         12339800
           MOVE WS-MENSAJE-TXT-EVE         TO TI-CF07-MSG-ERROR         12339900
           MOVE WS-PROGRAM                 TO TI-CF07-PROG              12340000
           MOVE TI-CF06-REG-TRANS          TO TI-CF07-REG-CF06-TRANS    12340100
      *                                                                 12340600
      *    EXEC  CICS  WRITE  FILE (TI-CW03-FILE-EVEN-LOG)              00160022
           EXEC  CICS  WRITE  FILE (WS-FILE-NM-EVEN-LOG)                00160022
                              FROM (TI-CF07-REG-TRANS)                  12340800
                            LENGTH (LENGTH OF TI-CF07-REG-TRANS)        12340900
                            RIDFLD (WS-RBA-ESDS)                        12341000
                               RBA                                      12341100
                              RESP (WS-RESP)                            12341200
           END-EXEC                                                     12341300
      *                                                                 12341400
           IF WS-RESP = DFHRESP(NORMAL)                                 12341500
              CONTINUE                                                  12341600
           ELSE                                                         12341700
      *GNS-I                                                                    
              SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                  05790000
              MOVE WS-COD-E-LOG-EVENTOS        TO WS-CODMSG             05800000
              MOVE WS-88-ERROR-GRABAR-LOGEVEN  TO WS-MENSAJE            05810000
              MOVE WS-CODMSG-ESTRUCTURA        TO WS-CSMT-COD-RETORNO   05800000
              MOVE WS-COD-PROG                 TO WS-CSMT-COD-PROGRAMA  05800000
              MOVE WS-TXTMSG                   TO WS-CSMT-MENSAJE       05800000
              PERFORM  6400-WRITE-CSMT                                  00160022
      *GNS-F                                                                    
              PERFORM  6000-FINAL                                       12342200
           END-IF.                                                      12342300
      ************************ FIN DE 6200-GRABAR-LOG-EVENTOS           12342400
      ************************                                          12342500
       6300-ACTUALIZA-COMAREA.                                          12342600
      ************************                                          12342700
      ******************************************************************12342800
      *ACTUALIZA COMMAREA CON CAMPO ERRADO                              12342900
      ******************************************************************12343000
      *GNS-I                                                                    
      *    MOVE WS-TEMP-XX           TO TI-TR02-RESPONSE-CODE-CCE       12343100
      *    MOVE WS-CT-NUMER          TO TI-TR02-COD-RESP-AMPLIADO       12343200
      *    MOVE WS-CT-001            TO TI-TR02-ORIGEN-RESPUESTA        12343300
      *    MOVE WS-MENSAJE-TXT       TO TI-TR02-MENSAJE-RESPUESTA       12343400
      *    MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     12343500
           MOVE WS-TEMP-XX           TO TI-TRR2-RESPONSE-CODE-CCE       12343100
           MOVE WS-TEMP-XXXX         TO TI-TRR2-COD-RESP-AMPLIADO       12343200
           MOVE TI-TRR2-I-TRAMA      TO DFHCOMMAREA                     12343500
      *GNS-F                                                                    
           .                                                            12343600
      ************************ FIN DE 6300-ACTUALIZA-COMAREA            12343700
      *****************                                                 00160022
       6400-WRITE-CSMT.                                                 00160022
      *****************                                                 00160022
      ******************************************************************00160022
      * ESCRIBE EN LA CSMT.                                            *00160022
      ******************************************************************00160022
                                                                        00160022
           EXEC CICS WRITEQ TD                                          00160022
                         QUEUE ('CSMT')                                 00160022
                          FROM (WS-REG-GRABAR-CSMT)                     00160022
                          RESP (WS-RESP)                                00160022
                         RESP2 (WS-RESP2)                               00160022
           END-EXEC                                                     00160022
           .                                                            00160022
      ************************ FIN DE 6400-WRITE-CSMT                   00160022
      *GNS-I                                                                    
      ********************                                              12343800
      *7200-RUT-LINK-GRAL.                                              12343900
      ********************                                              12344000
      ******************************************************************12345000
      * INVOCA CUALQUIER RUTINA VIA LINK, USANDO UNA COMMAREA COMUN    *12350000
      ******************************************************************12351000
      *                                                                 12370000
      *    EXEC  CICS LINK  PROGRAM (WS-RTN-SGTE)                       12380000
      *               COMMAREA      (WS-CCAA)                           12390000
      *               LENGTH        (WS-LGTH-CCAA)                      12400000
      *               RESP          (WS-RESP)                           12410000
      *               RESP2         (WS-RESP2)                          12420000
      *    END-EXEC                                                     12430000
      *                                                                 12440000
      *    IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                      12450000
      **       OBTENER MENSAJE PARA CCE                                 12502000
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12503000
      *                                                                 12504000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      12505000
      *        SET  TI-CF06-88-RECH        TO TRUE                      12506000
      *        MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 12507000
      *                                       WS-TEMP-XX                12508000
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12509000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *        MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 12509100
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12509200
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               12509300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
      *        MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  12509400
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             12509500
      *                                                                 12509600
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 12509700
      *        PERFORM 6300-ACTUALIZA-COMAREA                           12509800
      *                                                                 12509900
      **       OBTENER MENSAJE INTERNO                                  12510000
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      12510100
      *        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      12510200
      *        MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    12510300
      *                                       WS-CODMSG-ESTRUCTURA      12510400
      *                                       WS-COD-ERROR-07           12510500
      *        MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            12510600
      *                                       WS-PROGRAM                12510700
      *        MOVE 'LINK'                 TO WS-VARMSG-FUN             12510800
      *        MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             12510900
      *                                                                 12511000
      *        PERFORM 6100-OBTENER-MENSAJE                             12511100
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            12511200
      *                                                                 12511300
      *                                                                 12511400
      *        PERFORM 6200-GRABAR-LOG-EVENTOS                          12511500
      *        PERFORM 6000-FINAL                                       12511600
      *    END-IF                                                       12512000
      *    .                                                            12512100
      ************************ FIN DE 7200-RUT-LINK-GRAL                12513000
      *GNS-F                                                                    
      ***************                                                   12520000
       9000-TERMINAR.                                                   12530000
      ***************                                                   12531000
      ******************************************************************12532000
      * TERMINA PROGRAMA Y REGRESA A INVOCADOR                          12550000
      ******************************************************************12551000
                                                                        12570000
AJUSTA*GNS-I                                                                    
AJUSTA*    MOVE WS-CT-0210       TO TI-TR02-MSGE-TYPE-ID                12580000
AJUSTA*GNS-F                                                                    
           PERFORM 6000-FINAL                                           12590000
           .                                                            12591000
      ************************ FIN DE 6300-ACTUALIZA-COMAREA            12592000
      ********************                                              12600000
       9998-OBTIENE-ABEND.                                              12610000
      ********************                                              12611000
      ******************************************************************12612000
      * OBTIENE EL CODIGO DEL ABEND GENERADO POR EL MODULO            * 12630000
      ******************************************************************12631000
                                                                        12650000
           EXEC  CICS                                                   12660000
                                                                        12670000
                 ASSIGN ABCODE (WS-ABCODE)                              12680000
                     ABPROGRAM (WS-ABPROGRAM)                           12690000
           END-EXEC                                                     12700000
           .                                                            12701000
      ************************ FIN DE 9998-OBTIENE-ABEND                12702000
      *************************                                         12710000
       9999-MANEJO-EXCEPCIONES.                                         12720000
      *************************                                         12721000
      ******************************************************************12722000
      * MANEJO DE EXECPCIONES                                           12723000
      ******************************************************************12724000
                                                                        12760000
           PERFORM  9998-OBTIENE-ABEND                                  12770000
                                                                        12780000
      *GNS-I                                                                    
      *    SET  WS-SI-EXISTE-ERROR         TO TRUE                      12790000
      *GNS-F                                                                    
           MOVE 17                         TO WS-CODMSG                 12800000
           MOVE WS-ABCODE                  TO WS-MENSAJE                12810000
      *GNS-I                                                                    
           SET WS-CODTIP-88-ERROR-RECURSOS TO TRUE                      05790000
           MOVE WS-CODMSG-ESTRUCTURA       TO WS-CSMT-COD-RETORNO       05800000
           MOVE WS-COD-PROG                TO WS-CSMT-COD-PROGRAMA      05800000
           MOVE WS-TXTMSG                  TO WS-CSMT-MENSAJE           05800000
           PERFORM 6400-WRITE-CSMT                                      00160022
      *GNS-F                                                                    
      *GNS-I                                                                    
      *    PERFORM 6000-FINAL.                                          12820000
           PERFORM 6000-FINAL                                           12820000
      *GNS-F                                                                    
           .                                                            12821000
      ************************ FIN DE 9999-MANEJO-EXCEPCIONES           12822000
