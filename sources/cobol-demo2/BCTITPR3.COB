       IDENTIFICATION DIVISION.                                         00010000
      *************************                                         00020000
       PROGRAM-ID.    BCTITPR3.                                         00030000
       AUTHOR.        TCS - DANTE PANDO FLORES.                         00040000
       INSTALLATION.  BANCO DE CREDITO.                                 00050000
       DATE-WRITTEN.  ENE - 2015.                                       00060000
      *                                                                 00070000
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
      * OBJETIVOS :                                                    *00210000
      *                                                                *00220000
      *                                                                *00230000
      * FUNCIONES : 1. SE IMPLEMENTARA EL SERVICIO QUE SERÁ INVOCADO   *00240000
      *                POR SIX/STI DE NOVATRONIC CUANDO EL BCP SEA     *00250000
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
      *                                                                 00441001
      *----------------------------------------------------------------*00442001
      *              C O N T R O L   D E   C A M B I O S               *00443001
      *----------------------------------------------------------------*00444001
      * MODIFICACION  : MODIFICAR PROGRAMA PARA IMPLEMENTAR 24X7       *00444101
      * FECHA         : 03/09/2020                                     *00444201
      * AFECTA A      : BCP                                            *00444301
      * MODIFICADO POR: MPM                                            *00444401
      * NRO.TICKET    : TA000160022                                    *00444501
      ******************************************************************00444601
      *  MODIFICACION   : SE RECOMPILO PROGRAMA PARA QUE TOME CAMBIOS  *00445001
      *                 : DE COPY MODIFICADO                           *00446001
      *  FECHA          : 22/09/2016                                   *00447001
      *  AFECTA A       : BCP                                          *00448001
      *  MODIFICADO POR : LENIN QUIROZ - TCS                           *00449001
      *  NRO.TICKET     : TK000069579                                  *00449101
      *----------------------------------------------------------------*00449201
      * MODIFICACION  : VOCALINK                                       *00444101
      * FECHA         : 2022                                           *00444201
      * AFECTA A      : BCP                                            *00444301
      * MODIFICADO POR: TCS                                            *00444401
      * NRO.TICKET    : TA000184140                                    *00444501
      ******************************************************************00444601
      *                                                                 00449301
       ENVIRONMENT DIVISION.                                            00450000
      **********************                                            00460000
       DATA DIVISION.                                                   00470000
      *************************                                         00480000
       WORKING-STORAGE SECTION.                                         00490000
      *************************                                         00500000
       01  WS-VARIABLES-GENERALES.                                      00510000
           05  WS-RBA-ESDS               PIC S9(08)  COMP.              00520000
           05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR3'.  00530000
           05  WS-PROGRAM                PIC  X(08)  VALUE SPACES.      00531000
           05  WS-PROG-CONSULTA          PIC  X(08)  VALUE 'BCTITPR2'.  00540000
           05  WS-PROGRAM-TP80           PIC  X(08)  VALUE 'BCTITP80'.  00550000
           05  WS-RTN-SGTE               PIC  X(08)  VALUE SPACES.      00560000
           05  WS-PROG-CALLER            PIC  X(08)  VALUE 'BCTITPE0'.  00570000
           05  WS-RTN-BCRGTP05           PIC  X(08)  VALUE 'BCRGTP05'.  00580000
           05  WS-BCOQTP10               PIC  X(08)  VALUE 'BCOQTP10'.  00590000
           05  WS-RTN-TABPQTPB           PIC  X(08)  VALUE 'TABPQTPB'.  00600000
           05  WS-RTN-BCSTTP10           PIC  X(08)  VALUE 'BCSTTP10'.  00610000
           05  WS-RTN-ASIGNA-TETI        PIC  X(08)  VALUE 'BCRGTP04'.  00620000
           05  WS-RTN-SGCPPDGC           PIC  X(08)  VALUE 'SGCPPDGC'.  00630000
           05  WS-RTN-BCVPTP28           PIC  X(08)  VALUE 'BCVPTP28'.  00640000
           05  WS-RTN-BCRGTP04           PIC  X(08)  VALUE 'BCRGTP04'.  00650000
           05  WS-USUARIO                PIC  X(07)  VALUE '       '.   00660000
           05  WS-EYEID-ND               PIC  X(10)  VALUE 'NEXTDAYCOM'.00670000
           05  WS-APLID-SYST             PIC  X(04)  VALUE 'TTIB'.      00680000
           05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV03'.  00690000
           05  WS-DOC-ORD-CONST        PIC  X(12)  VALUE '000000000000'.00691000
           05  WS-DOC-ORD-CONSIST      PIC  X(12)  VALUE SPACES.        00692000
           05  WS-DOC-ORD-CCE          PIC  X(12)  VALUE SPACES.        00693000
           05  WS-DOC-ORD-TMP          PIC  X(12)  VALUE SPACES.        00694000
           05  WS-DOC-ORD-TMP2         PIC  X(12)  VALUE SPACES.        00695000
           05  WS-POS                  PIC  9(02)  VALUE ZEROS.         00696000
           05  WS-POS-INI              PIC  9(02)  VALUE ZEROS.         00697000
           05  WS-LENGHT-CAD           PIC  9(02)  VALUE ZEROS.         00698000
           05  WS-ABSTIME-PROC           PIC S9(15) COMP-3 VALUE +0.    00700000
           05  WS-VALIDA-PRG1            PIC  9(01)  VALUE 0.           00710000
           05  WS-NRO-OPERACION          PIC  9(08)  VALUE 0.           00711000
           05  WS-TMP-VC1                PIC  9(01)  VALUE 0.           00720000
           05  WS-TMP-CC1                PIC  X(30)  VALUE SPACES.      00730000
           05  WS-TR02-MSGE-TYPE-ID      PIC  X(30)                     00740000
                                         VALUE 'TI-TR02-MSGE-TYPE-ID'.  00750000
           05  WS-TR02-COD-PROCESO       PIC  X(30)                     00760000
                                         VALUE 'TI-TR02-COD-PROCESO '.  00770000
           05  WS-I-TRAMA                PIC X(1600).                   00780000
           05  WS-CT-10C                 PIC X(03)    VALUE '010'.      00790000
           05  WS-CT-05C                 PIC X(03)    VALUE '005'.      00800000
                                                                        00810000
           05  WS-LGTH-TEM               PIC S9(04) COMP VALUE 0.       00820000
           05  WS-PTR-TSIS-N             PIC S9(08) COMP VALUE 0.       00830000
           05  WS-PTR-TSIS-X   REDEFINES                                00840000
               WS-PTR-TSIS-N             PIC  X(04).                    00850000
           05  WS-PTR-TSIS     REDEFINES                                00860000
               WS-PTR-TSIS-N             USAGE IS POINTER.              00870000
           05  WS-BCOPZA.                                               00880000
               10 WS-CODREGI             PIC 9(02).                     00890000
               10 WS-BCODEST             PIC X(03).                     00900000
               10 WS-PZADEST             PIC X(03).                     00910000
           05  WS-LIMITE.                                               00920000
               10 WS-TIPPARM             PIC 9(02).                     00930000
               10 WS-TIPTRANS            PIC X(03).                     00940000
               10 WS-MONBCP              PIC X(04).                     00950000
               10 WS-TIPPZA              PIC X(01).                     00960000
               10 FILLER                 PIC X(20).                     00970000
           05 WS-FECHA-HORA-PROC.                                       00980000
               10 WS-FECHA-PROC          PIC 9(4).                      00990000
               10 WS-HORA-PROC           PIC 9(6).                      01000000
           05  WS-AREAID-I-CNL           PIC X(08).                     01010000
           05  WS-LGTH-I-OPE             PIC S9(04)  COMP VALUE 0.      01020000
           05  WS-LGTH-I-CNL             PIC S9(04)  COMP VALUE 0.      01030000
           05  WS-LGTH-O-CNL             PIC S9(04)  COMP VALUE 0.      01040000
           05  WS-PTR-I-CNL              USAGE IS POINTER.              01050000
           05  WS-PTR-I-CNL-X REDEFINES                                 01060000
               WS-PTR-I-CNL              PIC  X(04).                    01070000
           05  WS-PTR-I-CNL-N REDEFINES                                 01080000
               WS-PTR-I-CNL              PIC S9(08)  COMP.              01090000
           05  WS-SYSID-LOC              PIC  X(04) VALUE SPACES.       01120000
           05  WS-ABCODE                 PIC  X(04) VALUE SPACES.       01130000
           05  WS-ABPROGRAM              PIC  X(08) VALUE SPACES.       01140000
           05  WS-ABSTIME                PIC S9(15) COMP-3 VALUE +0.    01150000
           05  WS-FECHA-INI.                                            01160000
               10  WS-FEINI-CICS         PIC  9(08) VALUE 0.            01170000
               10  FILLER                PIC  X(02) VALUE SPACES.       01180000
           05  WS-HORA-INI.                                             01190000
               10  WS-HOINI-CICS         PIC  X(08) VALUE SPACES.       01200000
           05  WS-NUM-SEGUNDOS           PIC S9(08) COMP  VALUE +1.     01210000
           05  WS-HORA-SS-INI            PIC 9(04) VALUE 0.             01220000
           05  WS-HORA-SS-FIN            PIC 9(04) VALUE 0.             01230000
           05  WS-HORA-SS-CNL            PIC 9(04) VALUE 0.             01240000
           05  WS-FECHA-FIN.                                            01250000
               10  WS-FEFIN-CICS         PIC  9(08) VALUE 0.            01260000
               10  FILLER                PIC  X(02) VALUE SPACES.       01270000
           05  WS-HORA-FIN.                                             01280000
               10  WS-HOFIN-CICS         PIC  X(08) VALUE SPACES.       01290000
           05  WS-TIEMPO-PROC            PIC  9(03) VALUE ZEROS.        01300000
                                                                        01310000
           05  WS-RECURSOS-CICS.                                        01320000
               10  WS-TIPO-CONEX         PIC  X(02) VALUE '  '.         01330000
                   88  WS-CONEX-LINK         VALUE  'D ' 'DS'.          01340000
                   88  WS-CONEX-START        VALUE  'S ' 'SD' 'SZ'.     01350000
                   88  WS-CONEX-TRIGGER      VALUE  'QD'.               01360000
                   88  WS-CONEX-SEND         VALUE  'TD'.               01370000
                   88  WS-CONEX-TASK         VALUE  'U '.               01380000
               10  WS-TRANID             PIC  X(04) VALUE SPACES.       01390000
               10  WS-CONVID             PIC  X(04) VALUE SPACES.       01400000
               10  WS-APPLID             PIC  X(08) VALUE SPACES.       01410000
                                                                        01420000
           05  WS-RESP                   PIC S9(08)  COMP VALUE +0.     01430000
           05  WS-RESP2                  PIC S9(08)  COMP VALUE +0.     01440000
           05  WS-CODIGO-RESP            PIC  X(06).                    01450000
           05  WS-LONGITUD-RESP          PIC  9(05).                    01460000
           05  WS-IMPORTE                PIC X(20).                     01470000
           05  WS-IMPORTE-12             PIC X(12).                     01480000
           05  WS-IMPORTE-NV REDEFINES WS-IMPORTE-12   PIC 9(12).       01490000
           05  WS-CCAA                   PIC  X(32000).                 01500000
           05  WS-LGTH-CCAA              PIC S9(04)  VALUE +0 COMP.     01510000
      *                                                                 01520000
       02 WS-IMPORTE-20.                                                01530000
          05 WS-SIGNO                    PIC  X(01).                    01540000
          05 WS-SOLES                    PIC  9(14).                    01550000
          05 WS-PUNTO                    PIC  X(01).                    01560000
          05 WS-CENTI                    PIC  9(04).                    01570000
      *                                                                 01580000
       01  WS-CONSTANTES.                                               01590000
           05  WS-CT-TI             PIC X(02) VALUE 'TI'.               01600000
           05  WS-CT-00             PIC X(02) VALUE '00'.               01610000
           05  WS-CT-01             PIC X(02) VALUE '01'.               01611000
           05  WS-CT-02             PIC X(02) VALUE '02'.               01620000
           05  WS-CT-03             PIC X(02) VALUE '03'.               01630000
           05  WS-CT-04             PIC X(02) VALUE '04'.               01640000
           05  WS-CT-05             PIC X(02) VALUE '05'.               01650000
           05  WS-CT-06             PIC X(02) VALUE '06'.               01660000
           05  WS-CT-07             PIC X(02) VALUE '07'.               01670000
           05  WS-CT-004            PIC X(03) VALUE '004'.              01680000
           05  WS-CT-005            PIC X(03) VALUE '005'.              01690000
           05  WS-CT-0200           PIC X(04) VALUE '0200'.             01700000
           05  WS-CT-0201           PIC X(04) VALUE '0201'.             01710000
           05  WS-CT-800000         PIC X(06) VALUE '800000'.           01720000
           05  WS-CT-490000         PIC X(06) VALUE '490000'.           01730000
           05  WS-CTN-0             PIC 9(01) VALUE 0.                  01740000
           05  WS-CTN-1             PIC 9(01) VALUE 1.                  01750000
           05  WS-CT-1021           PIC X(04) VALUE '1021'.             01760000
           05  WS-CT-1001           PIC X(04) VALUE '1001'.             01761000
           05  WS-CT-001            PIC X(03) VALUE '001'.              01770000
           05  WS-CT-320            PIC 9(03) VALUE 320.                01780000
           05  WS-CT-325            PIC 9(03) VALUE 325.                01790000
           05  WS-CT-1002           PIC X(04) VALUE '1002'.             01800000
           05  WS-CT-1006           PIC X(04) VALUE '1006'.             01810000
           05  WS-CT-1007           PIC X(04) VALUE '1007'.             01820000
           05  WS-CT-1008           PIC X(04) VALUE '1008'.             01830000
           05  WS-CT-1009           PIC X(04) VALUE '1009'.             01840000
           05  WS-CT-1016           PIC X(04) VALUE '1016'.             01850000
           05  WS-CT-0000           PIC X(04) VALUE '0000'.             01860000
           05  WS-CT-6              PIC X(01) VALUE '6'.                01870000
           05  WS-CT-0002           PIC X(04) VALUE '0002'.             01880000
           05  WS-CT-0003           PIC X(04) VALUE '0003'.             01890000
           05  WS-CT-0007           PIC X(04) VALUE '0007'.             01900000
           05  WS-CT-2002           PIC X(04) VALUE '2002'.             01910000
           05  WS-CT-2008           PIC X(04) VALUE '2008'.             01920000
           05  WS-CT-0009           PIC X(04) VALUE '0009'.             01930000
           05  WS-CT-111            PIC X(03) VALUE '111'.              01940000
           05  WS-CT-054            PIC X(03) VALUE '054'.              01950000
           05  WS-CT-2              PIC X(01) VALUE '2'.                01960000
           05  WS-CT-L              PIC X(01) VALUE 'L'.                01970000
           05  WS-CT-TRANSOK        PIC X(14)                           01971000
                                              VALUE 'TRANSACCION-OK'.   01972000
      *                                                                 01980000
       01  WS-VALIDO                PIC X(1)  VALUE SPACES.             01990000
           88  WS-VALIDO-NUM      VALUE '0' '1' '2' '3' '4'             02000000
               '5' '6' '7' '8' '9'.                                     02010000
           88  WS-VALIDO-ALF      VALUE 'A' 'B' 'C' 'D' 'E'             02020000
               'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R'      02030000
               'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z'.                         02040000
      *                                                                 02050000
       01 WS-NROCLI-CONSIS-WORK     PIC X(08).                          02060000
       01 WS-NROCLI-CONSIS-WORK1    PIC X(08).                          02070000
      *                                                                 02080000
       01  WS-CONTADORES-FILES.                                         02090000
           10 WS-NC-COUNTER-NAME    PIC  X(16) VALUE SPACES.            02100000
           10 WS-NRO-OPER-COUNTER        PIC S9(08)  COMP  VALUE +0.    02110000
       01  WS-RPTA-MSG.                                                 02120000
           05  WS-CODMSG-ESTRUCTURA.                                    02130000
               10  WS-CODAPP             PIC  X(02)  VALUE  'TI'.       02140000
               10  WS-CODMSG             PIC  X(04).                    02150000
           05  WS-TXTMSG                 PIC  X(80)  VALUE SPACES.      02160000
       01  WS-SWITCHES.                                                 02170000
           05  WS-EXISTE-ERROR           PIC  X(01)  VALUE 'N'.         02180000
               88  WS-NO-EXISTE-ERROR                VALUE 'N'.         02190000
               88  WS-SI-EXISTE-ERROR                VALUE 'S'.         02200000
                                                                        02210000
           05  WS-TRANSFER-ENCONTRADO    PIC  X(01)  VALUE 'N'.         02220000
               88  WS-TRANSFER-ENCONTRADO-OK         VALUE 'N'.         02230000
               88  WS-TRANSFER-ENCONTRADO-NOOK       VALUE 'S'.         02240000
                                                                        02250000
           05  WS-TRAMA-INPUT            PIC  X(01)  VALUE 'N'.         02260000
               88  WS-TRAMAINP-OK                    VALUE 'N'.         02270000
               88  WS-TRAMAINP-NOOK                  VALUE 'S'.         02280000
                                                                        02290000
           05  WS-CANAL-ENCONTRADO       PIC  X(01)  VALUE 'N'.         02300000
               88  WS-CANAL-ENCONTRADO-OK            VALUE 'S'.         02310000
               88  WS-CANAL-ENCONTRADO-NOOK          VALUE 'N'.         02320000
                                                                        02330000
           05  WS-DOCUMENTO-ENCONTRADO   PIC  X(01)  VALUE 'N'.         02340000
               88  WS-ENCONTRADO-SI                  VALUE 'S'.         02350000
               88  WS-ENCONTRADO-NO                  VALUE 'N'.         02360000
                                                                        02370000
           05  WS-PARAMETRO-ENCONTRADO   PIC  X(01)  VALUE 'N'.         02380000
               88  WS-88-ENCONTRADO-OK               VALUE 'S'.         02390000
               88  WS-88-ENCONTRADO-NOOK             VALUE 'N'.         02400000
                                                                        02410000
           05  WS-LAST-RETRY             PIC  X(01)  VALUE 'N'.         02420000
               88  WS-NO-LAST-RETRY                  VALUE 'N'.         02430000
               88  WS-SI-LAST-RETRY                  VALUE 'S'.         02440000
       01  WS-CODIGOS-ERRORES.                                          02450000
           05  WS-COD-E-OBT-CONEXION      PIC  X(04) VALUE '0001'.      02460000
           05  WS-COD-E-OBT-SYSID         PIC  X(04) VALUE '0002'.      02470000
           05  WS-COD-E-OBTIENE-FECHA     PIC  X(04) VALUE '0003'.      02480000
           05  WS-COD-E-FORMATTIME        PIC  X(04) VALUE '0004'.      02490000
           05  WS-COD-E-CARGA-TSIS        PIC  X(04) VALUE '0005'.      02500000
           05  WS-COD-E-COMMAREA          PIC  X(04) VALUE '0006'.      02510000
           05  WS-COD-E-CANAL-INV         PIC  X(04) VALUE '0007'.      02520000
           05  WS-COD-E-TIP-PAGO          PIC  X(04) VALUE '0008'.      02530000
           05  WS-COD-E-COD-MON           PIC  X(04) VALUE '0009'.      02540000
           05  WS-COD-E-TIP-TRN           PIC  X(04) VALUE '0010'.      02550000
           05  WS-COD-E-INTERNO-BCTITP8   PIC  X(04) VALUE '0011'.      02560000
           05  WS-COD-E-ACTUALIZ          PIC  X(04) VALUE '0012'.      02570000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(04) VALUE '0013'.      02580000
           05  WS-COD-E-READ-UBIGEO       PIC  X(04) VALUE '0014'.      02590000
           05  WS-COD-E-TRAMA-CONS        PIC  X(04) VALUE '0015'.      02600000
           05  WS-COD-E-CONS-INCOR        PIC  X(04) VALUE '0016'.      02610000
           05  WS-COD-E-TARIFA-NO-FOUND   PIC  X(04) VALUE '0017'.      02620000
           05  WS-COD-E-RANGO-NO-FOUND    PIC  X(04) VALUE '0018'.      02630000
           05  WS-COD-E-RANGO-MENOR       PIC  X(04) VALUE '0019'.      02640000
           05  WS-COD-E-ACCESO-MAESTRO    PIC  X(04) VALUE '0020'.      02650000
           05  WS-COD-E-DUP-RECORD        PIC  X(04) VALUE '0021'.      02660000
           05  WS-COD-E-ARCHIVO-LOG       PIC  X(04) VALUE '0022'.      02670000
           05  WS-COD-E-LINK-GRAL         PIC  X(04) VALUE '0023'.      02680000
           05  WS-COD-E-NEXT-PROC         PIC  X(04) VALUE '0024'.      02690000
           05  WS-COD-E-ASKTIME           PIC  X(04) VALUE '0024'.      02700000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(04) VALUE '0025'.      02710000
           05  WS-COD-E-INTERNO-BCTITP80  PIC  X(04) VALUE '0026'.      02720000
           05  WS-COD-E-IMPORTE-SUP       PIC  X(04) VALUE '0027'.      02730000
                                                                        02730100
       01  WS-VARIABLES-ERROR.                                          02731000
           05  WS-VARMSG-FUN             PIC  X(20)  VALUE SPACES.      02732000
           05  WS-VARMSG-RSO             PIC  X(20)  VALUE SPACES.      02733000
           05  WS-VARMSG-ARG             PIC  X(20)  VALUE SPACES.      02734000
           05  WS-VARMSG-TXT             PIC  X(30)  VALUE SPACES.      02735000
           05  WS-VARMSG-OPE             PIC  X(20)  VALUE SPACES.      02736000
                                                                        02737001
       01  WS-FILE-NAME-TTIB.                                           02738001
           05  WS-FILE-NM-MAESTRO          PIC  X(08)  VALUE SPACES.    02739001
           05  WS-FILE-NM-MAESTRO-ALT      PIC  X(08)  VALUE SPACES.    02739101
           05  WS-FILE-NM-MAESTRO-ALT2     PIC  X(08)  VALUE SPACES.    02739201
           05  WS-FILE-NM-EVEN-LOG         PIC  X(08)  VALUE SPACES.    02739201
                                                                        02739301
      *                                                                 02740000
       01  WA-VARIABLE1.                                                02750000
           05  WSV-MONTO20                PIC  X(20) VALUE              02760000
               ' 00000000000000.0000'.                                  02770000
           05  WSV-MONTOS                 PIC  X(20) VALUE SPACES.      02780000
           05  WSV-MONTO-A                PIC  X(18) VALUE SPACES.      02790000
           05  WSV-MONTO-N REDEFINES WSV-MONTO-A PIC S9(14)V9(04).      02800000
      *                                                                 02810000
           05  WSV-MONT12                 PIC  X(12) VALUE              02820000
               ' 0000.000000'.                                          02830000
           05  WSV-MONT12-A               PIC  X(10) VALUE SPACES.      02840000
           05  WSV-MONT12-N REDEFINES WSV-MONT12-A PIC S9(04)V9(06).    02850000
           05  WS-RESP-TXT                PIC  X(10) VALUE SPACES.      02860000
           05  WS-CADENA-TXT              PIC  X(50) VALUE SPACES.      02870000
           05  WS-CT-NUMER                PIC  X(04) VALUE SPACES.      02880000
           05  WS-TEMP-XX                 PIC  X(02) VALUE SPACES.      02881000
           05  WS-MENSAJE-TXT             PIC  X(80) VALUE SPACES.      02890000
           05  WS-MENSAJE-TXT-EVE         PIC  X(80)  VALUE SPACES.     02891000
           05  WS-CT-0                    PIC  9(01) VALUE 0.           02900000
           05  WS-CT-1                    PIC  9(01) VALUE 1.           02910000
           05  WS-CTN-12                  PIC  9(02) VALUE 12.          02911000
           05  WS-CT-1N                   PIC  9(01) VALUE 1.           02920000
           05  WS-CT-604                  PIC  9(03) VALUE 604.         02930000
           05  WS-CT-840                  PIC  9(03) VALUE 840.         02940000
           05  WS-CT-4                    PIC  9(01) VALUE 4.           02950000
           05  WS-COD-ERROR-07            PIC  X(06) VALUE '000000'.    02951000
           05  WS-A                       PIC  X(01) VALUE 'A'.         02960000
           05  WS-D                       PIC  X(01) VALUE 'D'.         02970000
           05  WS-Q                       PIC  X(01) VALUE 'Q'.         02980000
           05  WS-1                       PIC  9(01) VALUE 0.           02990000
           05  WS-COD-00                  PIC  X(02) VALUE '00'.        03000000
           05  WS-ERROR-TC                PIC  9(01) VALUE 0.           03010000
           05  IND                        PIC  9(05) VALUE 0.           03020000
           05  WS-CONTA                   PIC  9(05) VALUE 0.           03030000
           05  I                          PIC  9(05) VALUE 0.           03040000
           05  WS-TIPO-DOC-ORD-HOMOL      PIC  X(01) VALUE SPACES.      03050000
           05  WS-CT-SPACE4               PIC  X(04) VALUE SPACES.      03060000
           05  WS-CT-0001                 PIC  9(04) VALUE 0001.        03070000
           05  WS-EIBRESP                 PIC S9(08).                   03080000
           05  WS-EIBRESP2                PIC S9(08).                   03090000
           05  WS-CT-S                    PIC  X(01) VALUE 'S'.         03100000
           05  WS-CT-M                    PIC  X(01) VALUE 'M'.         03110000
           05  WS-CT-CTPB                 PIC  X(04) VALUE 'CTPB'.      03120000
           05  WS-CT-TPB                  PIC  X(03) VALUE 'TPB'.       03130000
           05  WS-CT-063                  PIC  X(03) VALUE '063'.       03140000
           05  WS-CT-08C                  PIC  X(03) VALUE '008'.       03150000
           05  WS-TMP-ICLI                PIC  X(08) VALUE SPACES.      03160000
           05  WS-IDC                     PIC  X(16) VALUE SPACES.      03170000
           05  WS-J                       PIC  9(02) VALUE 0.           03180000
           05  WS-K                       PIC  9(02) VALUE 0.           03190000
           05  WS-X                       PIC  9(2)  VALUE ZEROS.       03191000
           05  WS-TX-MSJE                 PIC  X(80) VALUE SPACES.      03200000
           05  WS-DGC-CRETORNO            PIC  X(04) VALUE SPACES.      03210000
           05  WS-0000000                 PIC  X(07) VALUE '       '.   03220000
           05  WS-000000                  PIC  X(06) VALUE '      '.    03230000
           05  WS-013                     PIC  X(03) VALUE '013'.       03240000
           05  WS-014                     PIC  X(03) VALUE '014'.       03250000
           05  WS-0000                    PIC  X(04) VALUE '0000'.      03260000
           05  WS-000                     PIC  X(03) VALUE '000'.       03270000
           05  WS-003                     PIC  X(03) VALUE '003'.       03280000
           05  WS-082                     PIC  X(03) VALUE '082'.       03290000
           05  WS-CT-GN4904               PIC  X(06) VALUE 'GN4904'.    03291000
                                                                        03300000
       01  WS-DESCRIPCION-ERRORES.                                      03310000
           05  WS-88-ERROR-OBT-CONEXION  PIC  X(80) VALUE               03320000
               'ERROR EN ACCESO ARCHIVO LOG                           '.03330000
           05  WS-88-ERROR-OBT-SYSID     PIC  X(80) VALUE               03340000
               'ERROR EN INVOKINGPROG                                 '.03350000
           05  WS-88-ERROR-OBTIENE-FECHA PIC  X(80) VALUE               03360000
               'ERROR AL RECUPERAR LA FECHA DEL SISTEMA               '.03370000
           05  WS-88-ERROR-FORMATTIME    PIC  X(80) VALUE               03380000
               'ERROR EN FORMATTIME                                   '.03390000
           05  WS-88-ERROR-CARGA-TSIS    PIC  X(80) VALUE               03400000
               'ERROR AL CARGAR LA TABLA DEL SISTEMA                  '.03410000
           05  WS-88-ERROR-COMMAREA      PIC  X(80) VALUE               03420000
               'ERROR AL OBTENER CONEXION                             '.03430000
           05  WS-88-ERROR-CANAL-INV     PIC  X(80) VALUE               03440000
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.03450000
           05  WS-88-ERROR-TIP-PAGO      PIC  X(80) VALUE               03460000
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.03470000
           05  WS-88-ERROR-COD-MON       PIC  X(80) VALUE               03480000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03490000
           05  WS-88-ERROR-TIP-TRN       PIC  X(80) VALUE               03500000
               'NEXT DAY EN PROCESO                                   '.03510000
           05  WS-ERROR-INTERNO-BCTITP80 PIC  X(80) VALUE               03520000
               'NEXT DAY INICIO                                       '.03530000
           05  WS-88-ERROR-ACTUALIZ      PIC  X(80) VALUE               03540000
               'ERROR AL OBTENER COUNTER                              '.03550000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(80) VALUE              03560000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.03570000
           05  WS-88-ERROR-TRAMA-CONS    PIC  X(80) VALUE               03580000
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.03590000
           05  WS-88-ERROR-CONS-INCOR    PIC  X(80) VALUE               03600000
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.03610000
           05  WS-88-ERROR-RANGO-NO-FOUND PIC  X(80) VALUE              03620000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03630000
           05  WS-88-ERROR-RANGO-MENOR   PIC  X(80) VALUE               03640000
               'NEXT DAY EN PROCESO                                   '.03650000
           05  WS-88-ERROR-ACCESO-MAESTRO PIC  X(80) VALUE              03660000
               'NEXT DAY INICIO                                       '.03670000
           05  WS-88-ERROR-DUP-RECORD    PIC  X(80) VALUE               03680000
               'ERROR AL OBTENER COUNTER                              '.03690000
           05  WS-88-ERROR-ARCHIVO-LOG    PIC  X(80) VALUE              03700000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.03710000
           05  WS-88-ERROR-LINK-GRAL      PIC  X(80) VALUE              03720000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03730000
           05  WS-88-ERROR-NEXT-PROC     PIC  X(80) VALUE               03740000
               'NEXT DAY EN PROCESO                                   '.03750000
           05  WS-88-ERROR-ASKTIME        PIC  X(80) VALUE              03760000
               'NEXT DAY INICIO                                       '.03770000
           05  WS-88-ERROR-REGISTRO-NO-FOUND PIC X(80) VALUE            03780000
               'ERROR AL OBTENER COUNTER                              '.03790000
           05  WS-88-ERROR-READ-UBIGEO    PIC  X(80) VALUE              03800000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.03810000
           05  WS-88-ERROR-IMPORTE-SUP    PIC  X(80) VALUE              03820000
               'IMPORTE SUPERIOR                                      '.03830000
                                                                        03840000
      ******************************************************************03850000
      *                TABLA DE CODIGOS DE RESPUESTA                   *03860000
      ******************************************************************03870000
      *                                                                 04070000
       01  WS-COD-ORIG.                                                 04080000
           10  WS-COD-RESP              PIC X(04).                      04090000
           10  FILLER                   PIC X(01) VALUE SPACES.         04100000
           10  WS-ORI-RESP              PIC X(03).                      04110000
      *                                                                 04120000
      ******************************************************************04130000
      *                COPYBOOKS Y COMMAREAS DE TRABAJO                *04140000
      ******************************************************************04150000
      *--------------  COMMAREA PARA PROGRAMAS DE RECEPTOR              04160001
       COPY BCTICA02.                                                   04170001
                                                                        04170101
      *--------------  COPY DE COMUNICACION PARA RUTINA DE MENSAJES     04171000
       COPY BCTICA15.                                                   04172000
                                                                        04173000
      *-------------- COPY DE ARCHIVO LOG                               04180000
       COPY BCTICF07.                                                   04190000
                                                                        04191000
      *-------------- COPY DE ARCHIVO MAESTRO DE TRANSACCIONES          04200000
       COPY BCTICF06.                                                   04210000
                                                                        04211000
      *-------------- COPY DE ARCHIVO DE PARAMETROS                     04220000
       COPY BCTICF01.                                                   04230000
                                                                        04230100
      *--------------  COPY TRAMA INPUT/OUTPUT NOVATRONICS              04231000
       COPY BCTITR02.                                                   04232000
                                                                        04233000
      *-------------- COPY RUTINA DE ACCESO AL ARCHIVO DE PARáMETROS DE 04280000
       COPY BCRGCA05.                                                   04290000
                                                                        04291000
      *-------------- COPY RUTINA DE ASIGNACIóN DINáMICA DE USUARIO Y TE04300000
       COPY BCRGCA04.                                                   04310000
                                                                        04311000
      *-------------- COPY AREA DE COMUNICACION CTAS TRANSFER Y BUCKETS 04312000
       COPY BCRGCA10.                                                   04313000
                                                                        04314000
      *-------------- COPY RUTINA SGCPPDGC-ONLINE/SGCPGDGC-BATCH  PARA A04314100
       COPY SGCWGDGC.                                                   04314200
                                                                        04314300
      *-------------- COPY AREA DE COMUNICACION - BSC                   04314400
       COPY TABWGTPB.                                                   04314500
                                                                        04314600
      *-------------- COPY MQSERIES/HOST PARA CONSULTAS IMPACS          04315000
       COPY BCIMYR8S.                                                   04316000
                                                                        04317000
      *-------------- COPY MQSERIES/HOST PARA CONSULTAS SAVING          04318000
       COPY BCSTYR80.                                                   04319000
                                                                        04319100
      *-------------- COPY DE SERVICIO VP28 DE VPLUS                    04340000
       COPY BCVPAR05.                                                   04350000
                                                                        04351000
      *-------------- COPY TRAMA DE MACRO-OPERACION BUKCTA              04391000
       COPY BCOQTR27.                                                   04400000
      *                                                                 04410000
      *****************                                                 04420000
       LINKAGE SECTION.                                                 04430000
      *****************                                                 04440000
      *01  DFHCOMMAREA                 PIC  X(1540).                    00160022
       01  DFHCOMMAREA                 PIC  X(2000).                    00160022
                                                                        04451000
      *--------------  TABLA DEL SISTEMA TTIB ONLINE                    04452000
       COPY BCTICW03.                                                   04453000
                                                                        04454000
      ********************                                              04460000
       PROCEDURE DIVISION.                                              04470000
      ********************                                              04480000
                                                                        04490000
           PERFORM  1000-INICIO                                         04500000
                                                                        04510000
           IF  WS-NO-EXISTE-ERROR                                       04520000
               PERFORM  3000-PROCESO                                    04530000
           END-IF                                                       04540000
                                                                        04550000
           PERFORM  9000-TERMINAR                                       04560000
           .                                                            04561000
      ************************ FIN DE PROCEDURE DIVISION                04562000
      *************                                                     04570000
       1000-INICIO.                                                     04580000
      *************                                                     04581000
      ******************************************************************04590000
      * RECIBE COMMAREA                                                *04600000
      ******************************************************************04601000
                                                                        04620000
           EXEC  CICS                                                   04630000
               HANDLE ABEND                                             04640000
                      LABEL (9999-MANEJO-EXCEPCIONES)                   04650000
           END-EXEC                                                     04660000
                                                                        04670000
           PERFORM  1005-OBTIENE-SYSID                                  04680000
           PERFORM  1020-OBTIENE-FECHA-HORA-INICIO                      04690000
           PERFORM  1100-RECIBE-COMMAREA                                04700000
           PERFORM  1200-CARGA-TABLA-SIST-TTIB                          04710000
           PERFORM  1300-LEE-TRANSFERENCIA                              04711000
           PERFORM  1400-INVOCA-RUT-BCRGTP05                            04720000
           .                                                            04720100
      ************************ FIN DE 1000-INICIO                       04721000
      ********************                                              04730000
       1005-OBTIENE-SYSID.                                              04740000
      ********************                                              04741000
      ******************************************************************04742000
      * OBTIENE EL SYSID DEL CICS DONDE SE EJECUTA EL PROGRAMA         *04760000
      ******************************************************************04761000
                                                                        04780000
           EXEC  CICS  ASSIGN                                           04790000
                 INVOKINGPROG (WS-PROG-CALLER)                          04800000
                    STARTCODE (WS-TIPO-CONEX)                           04810000
                        SYSID (WS-SYSID-LOC)                            04820000
                       USERID (WS-USUARIO)                              04830000
                         RESP (WS-RESP)                                 04840000
                        RESP2 (WS-RESP2)                                04850000
           END-EXEC                                                     04860000
                                                                        04870000
           IF  WS-RESP     NOT EQUAL TO    DFHRESP(NORMAL)              04880000
               SET  WS-SI-EXISTE-ERROR         TO TRUE                  04890000
               MOVE WS-COD-E-OBT-SYSID         TO WS-CODMSG             04900000
               MOVE WS-88-ERROR-OBT-SYSID      TO WS-TXTMSG             04910000
               PERFORM  6000-FINAL                                      04920000
                                                                        04921000
           END-IF                                                       04930000
           .                                                            04930100
      ************************ FIN DE 1005-OBTIENE-SYSID                04931000
      ********************************                                  04932000
       1020-OBTIENE-FECHA-HORA-INICIO.                                  04950000
      ********************************                                  04950100
      ******************************************************************04951000
      * RECUPERAMOS LA FECHA Y HORA DE INICIO  DESDE EL CICS.          *04970000
      ******************************************************************04971000
                                                                        04990000
           EXEC  CICS  ASKTIME                                          05000000
                       ABSTIME (WS-ABSTIME)                             05010000
                          RESP (WS-RESP)                                05020000
                         RESP2 (WS-RESP2)                               05030000
           END-EXEC                                                     05040000
      *                                                                 05050000
           IF  WS-RESP     NOT EQUAL          TO DFHRESP(NORMAL)        05060000
               SET  WS-SI-EXISTE-ERROR        TO TRUE                   05070000
               MOVE WS-COD-E-OBTIENE-FECHA    TO WS-CODMSG              05080000
               MOVE WS-88-ERROR-OBTIENE-FECHA TO WS-TXTMSG              05090000
                                                                        05091000
           END-IF                                                       05100000
      *                                                                 05110000
           EXEC  CICS  FORMATTIME                                       05120000
                          ABSTIME (WS-ABSTIME)                          05130000
                         YYYYMMDD (WS-FECHA-INI)                        05140000
                             TIME (WS-HORA-INI)                         05150000
                          TIMESEP                                       05160000
                             RESP (WS-RESP)                             05170000
                            RESP2 (WS-RESP2)                            05180000
           END-EXEC                                                     05190000
      *                                                                 05200000
           IF  WS-RESP  NOT EQUAL TO  DFHRESP(NORMAL)                   05210000
                SET  WS-SI-EXISTE-ERROR     TO TRUE                     05220000
                MOVE WS-COD-E-FORMATTIME    TO WS-CODMSG                05230000
                MOVE WS-88-ERROR-FORMATTIME TO WS-TXTMSG                05240000
                PERFORM 6000-FINAL                                      05250000
                                                                        05251000
           END-IF                                                       05260000
           .                                                            05260100
      ************************ FIN DE 1020-OBTIENE-FECHA-HORA-INICIO    05261000
      **********************                                            05262000
       1100-RECIBE-COMMAREA.                                            05280000
      **********************                                            05281000
      ******************************************************************05282000
      * IDENTIFICA A PARTIR DE LOS RECURSOS CICS EL TIPO DE LLAMADA A  *05300000
      * NUESTRO PROGRAMA Y RECIBE LA TRAMA DE ENTRADA.                 *05310000
      ******************************************************************05311000
                                                                        05312000
           IF  EIBCALEN  GREATER  0                                     05330000
      *        MOVE DFHCOMMAREA          TO TI-TR02-I-TRAMA             00160022
               MOVE DFHCOMMAREA            TO TI-CA02-AREA-COMUNICACION 00160022
               MOVE TI-CA02-REG-TRANS-DATA TO TI-TR02-I-TRAMA           00160022
                                                                        05341000
               MOVE TI-CA02-FILE-NAME-MAESTRO                           00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
               MOVE TI-CA02-FILE-NAME-MAESTRO-ALT                       00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
               MOVE TI-CA02-FILE-NAME-MAESTRO-ALT2                      00160022
                                           TO WS-FILE-NM-MAESTRO-ALT2   00160022
               MOVE TI-CA02-FILE-NAME-EVEN-LOG                          00160022
                                           TO WS-FILE-NM-EVEN-LOG       00160022
                                                                        05341000
           ELSE                                                         05350000
               SET  WS-SI-EXISTE-ERROR   TO TRUE                        05360000
               MOVE WS-COD-E-COMMAREA    TO WS-CODMSG                   05370000
               MOVE WS-88-ERROR-COMMAREA TO WS-TXTMSG                   05380000
               PERFORM 6000-FINAL                                       05390000
                                                                        05391000
           END-IF                                                       05400000
           .                                                            05401000
      ************************ FIN DE 1100-RECIBE-COMMAREA              05402000
      ****************************                                      05402100
       1200-CARGA-TABLA-SIST-TTIB.                                      05402200
      ****************************                                      05402300
      ******************************************************************05402400
      * OBTIENE EL SYSID DE LA REGION CICS DONDE SE EJECUTA EL PRGM. Y *05402500
      * CARGA  LA TABLA DEL SYSTEMA TTIB                               *05402600
      ******************************************************************05402700
                                                                        05402800
           EXEC  CICS  LOAD                                             05402900
                    PROGRAM (WS-TSIS-TTIB)                              05403000
                        SET (WS-PTR-TSIS)                               05403100
                       RESP (WS-RESP)                                   05403200
                      RESP2 (WS-RESP2)                                  05403300
           END-EXEC                                                     05403400
                                                                        05403500
           IF  WS-RESP EQUAL DFHRESP(NORMAL)                            05403600
               SET  ADDRESS OF TI-CW03-REG-TABLA-SISTEMA                05403700
                                           TO WS-PTR-TSIS               05403800
           ELSE                                                         05403900
      *        OBTENER MENSAJE PARA CCE                                 05404000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05404100
                                                                        05404200
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      05404300
               SET  TI-CF06-88-RECH        TO TRUE                      05404400
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     05404500
                                          WS-TEMP-XX                    05404600
                                          WS-CODMSG-ESTRUCTURA(1: 2)    05404700
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     05404800
                                          WS-CODMSG-ESTRUCTURA(3: 4)    05404900
               MOVE WS-CT-1021         TO WS-CT-NUMER                   05405000
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      05405100
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             05405200
                                                                        05405300
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     05405400
               PERFORM 5600-ACTUALIZA-COMAREA                           05405500
                                                                        05405600
      *        OBTENER MENSAJE INTERNO                                  05405700
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05405800
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      05405900
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    05406000
                                              WS-CODMSG-ESTRUCTURA      05406100
                                              WS-COD-ERROR-07           05406200
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            05406300
                                              WS-PROGRAM                05406400
               MOVE 'LOAD'                 TO WS-VARMSG-FUN             05406500
               MOVE WS-TSIS-TTIB           TO WS-VARMSG-RSO             05406600
                                                                        05406700
               PERFORM 6100-OBTENER-MENSAJE                             05406800
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            05406900
                                              WS-MENSAJE-TXT-EVE        05407000
                                                                        05407100
               PERFORM 5700-GRABAR-LOG-EVENTOS                          05407200
               PERFORM 6000-FINAL                                       05407300
           END-IF                                                       05407400
           .                                                            05407500
      ************************ FIN DE 1200-CARGA-TABLA-SIST-TTIB        05407600
      ************************                                          05408000
       1300-LEE-TRANSFERENCIA.                                          05420000
      ************************                                          05421000
      ******************************************************************05422000
      * ASIGNAMOS VALORES DE KEY PARA LEER MAESTRA DE TRANSFERENCIAS.  *05440000
      ******************************************************************05441000
                                                                        05442000
           SET  TI-CF06-88-COD-PROCESO-TRN TO TRUE                      05460000
           SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      05470000
           MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 05480000
           MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         05490000
           MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   05500000
           MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       05510000
           MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       05520000
           MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        05530000
      *                                                                 05540000
      *    EXEC CICS READ DATASET (TI-CW03-FILE-MAESTRO)                00160022
           EXEC CICS READ    FILE (WS-FILE-NM-MAESTRO)                  00160022
                             INTO (TI-CF06-REG-TRANS)                   00160022
                           LENGTH (LENGTH OF TI-CF06-REG-TRANS)         00160022
                           RIDFLD (TI-CF06-REG-KEY-TRANS)               00160022
                        KEYLENGTH (LENGTH OF TI-CF06-REG-KEY-TRANS)     00160022
                           UPDATE                                       05591000
                             RESP (WS-RESP)                             00160022
           END-EXEC                                                     05610000
      *                                                                 05620000
           IF  WS-RESP = DFHRESP (NORMAL)                               05630000
      *        PENDIENTE                                                05640000
               IF  TI-CF06-ESTADO = WS-CT-01                            05650000
                   CONTINUE                                             05670000
               ELSE                                                     05680000
                   IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201                00160022
                       AND TI-TR02-COD-PROCESO  = WS-CT-490000          00160022
                       AND TI-CF06-ESTADO = WS-CT-02                    00160022
                       AND TI-CF06-COD-RESP-AMPLIADO = WS-CT-1021       00160022
                       SET  TI-CF06-88-SI-REENV    TO TRUE              00160022
                   ELSE                                                 00160022
      *            OBTENER MENSAJE PARA CCE                             05772000
                       MOVE SPACES             TO TI-CA15-I-O-MENSAJES  05773000
                                                                        05774000
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              05775000
                       SET  TI-CF06-88-RECH        TO TRUE              05776000
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 05777000
                                              WS-TEMP-XX                05778000
                                              WS-CODMSG-ESTRUCTURA(1: 2)05779000
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 05779100
                                              WS-CODMSG-ESTRUCTURA(3: 4)05779200
                       MOVE WS-CT-1021     TO WS-CT-NUMER               05779300
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  05779400
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     05779500
                                                                        05779600
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 05779700
                                                                        05779800
      *            OBTENER MENSAJE INTERNO                              05779900
                       MOVE WS-CODMSG-ESTRUCTURA                        05780000
                                           TO WS-COD-ERROR-07           05780100
                       MOVE WS-PROGRAM-ID  TO WS-PROGRAM                05780200
                                                                        05780500
                       MOVE WS-MENSAJE-TXT TO WS-MENSAJE-TXT-EVE        05780400
                                                                        05780600
                                                                        05780600
                       PERFORM 5600-ACTUALIZA-COMAREA                   05780700
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  05780800
                       PERFORM 6000-FINAL                               05780900
                   END-IF                                               00160022
               END-IF                                                   05781000
                                                                        05782000
           ELSE                                                         05790000
               MOVE WS-RESP            TO WS-RESP-TXT                   05800000
      *        OBTENER MENSAJE PARA CCE                                 05872000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05873000
                                                                        05874000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      05875000
               SET  TI-CF06-88-RECH        TO TRUE                      05876000
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     05877000
                                          WS-TEMP-XX                    05878000
                                          WS-CODMSG-ESTRUCTURA(1: 2)    05879000
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     05879100
                                          WS-CODMSG-ESTRUCTURA(3: 4)    05879200
               MOVE WS-CT-1021         TO WS-CT-NUMER                   05879300
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      05879400
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             05879500
                                                                        05879600
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     05879700
               PERFORM 5600-ACTUALIZA-COMAREA                           05879800
                                                                        05879900
      *        OBTENER MENSAJE INTERNO                                  05880000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05880100
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      05880200
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    05880300
                                              WS-CODMSG-ESTRUCTURA      05880400
                                              WS-COD-ERROR-07           05880500
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            05880600
                                              WS-PROGRAM                05880700
               MOVE 'READ'                 TO WS-VARMSG-FUN             05880800
      *        MOVE TI-CW03-FILE-MAESTRO   TO WS-VARMSG-RSO             00160022
               MOVE WS-FILE-NM-MAESTRO     TO WS-VARMSG-RSO             00160022
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             05881000
                                                                        05881100
               PERFORM 6100-OBTENER-MENSAJE                             05881200
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            05881300
                                              WS-MENSAJE-TXT-EVE        05881400
                                                                        05881500
               PERFORM 5700-GRABAR-LOG-EVENTOS                          05881600
               PERFORM 6000-FINAL                                       05881700
           END-IF                                                       05881800
           .                                                            05881900
      ************************ FIN DE 1300-LEE-TRANSFERENCIA            05882000
      **************************                                        05882100
       1400-INVOCA-RUT-BCRGTP05.                                        05883000
      **************************                                        05884000
      ******************************************************************05885000
      * INVOCA PROGRAMA BCRGTP05 -                                     *05886000
      ******************************************************************05887000
           SET RG-CA05-I-AMB-ACT    TO TRUE                             05888000
           SET RG-CA05-I-1RA-CON-SI TO TRUE.                            05889000
                                                                        05890000
           EXEC CICS LINK PROGRAM  (WS-RTN-BCRGTP05)                    05900000
                          COMMAREA (RG-CA05-COMMAREA)                   05910000
                          LENGTH   (LENGTH OF RG-CA05-COMMAREA)         05920000
                          RESP     (WS-RESP)                            05930000
           END-EXEC.                                                    05940000
      *                                                                 05950000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        06000000
      *        OBTENER MENSAJE PARA CCE                                 06010000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06020000
                                                                        06030000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      06040000
               SET  TI-CF06-88-RECH        TO TRUE                      06050000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 06060000
                                              WS-TEMP-XX                06070000
                                              WS-CODMSG-ESTRUCTURA(1: 2)06080000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 06090000
                                              WS-CODMSG-ESTRUCTURA(3: 4)06100000
               MOVE WS-CT-1021             TO WS-CT-NUMER               06110000
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  06120000
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             06130000
                                                                        06140000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 06150000
               PERFORM 5600-ACTUALIZA-COMAREA                           06160000
                                                                        06170000
      *        OBTENER MENSAJE INTERNO                                  06180000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06190000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      06200000
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    06210000
                                              WS-CODMSG-ESTRUCTURA      06220000
                                              WS-COD-ERROR-07           06230000
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            06240000
                                              WS-PROGRAM                06241000
               MOVE 'LINK'                 TO WS-VARMSG-FUN             06250000
               MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             06260000
                                                                        06270000
               PERFORM 6100-OBTENER-MENSAJE                             06280000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            06290000
                                              WS-MENSAJE-TXT-EVE        06300000
                                                                        06310000
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     06311000
               PERFORM 5700-GRABAR-LOG-EVENTOS                          06320000
               PERFORM 6000-FINAL                                       06330000
           ELSE                                                         06340000
               IF  RG-CA05-O-RET-NRO = WS-CT-0000                       06350000
                   CONTINUE                                             06360000
               ELSE                                                     06361000
      *            OBTENER MENSAJE PARA CCE                             06362000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  06363000
                                                                        06364000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  06365000
                   SET  TI-CF06-88-RECH        TO TRUE                  06366000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 06367000
                                              WS-TEMP-XX                06368000
                                              WS-CODMSG-ESTRUCTURA(1: 2)06369000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 06369100
                                              WS-CODMSG-ESTRUCTURA(3: 4)06369200
                   MOVE WS-CT-1021         TO WS-CT-NUMER               06369300
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  06369400
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         06369500
                                                                        06369600
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 06369700
                                                                        06369800
      *            OBTENER MENSAJE INTERNO                              06369900
                   MOVE RG-CA05-O-RETORNO  TO TI-CF06-CODMSG-ESTRUCT    06370000
                                              WS-COD-ERROR-07           06370100
                   MOVE WS-RTN-BCRGTP05    TO TI-CF06-PRGNOM            06370200
                                              WS-PROGRAM                06370300
                   MOVE RG-CA05-O-MSJ-RET  TO TI-CF06-TXTMSG            06370400
                                              WS-MENSAJE-TXT-EVE        06370500
                                                                        06370600
                   PERFORM 5600-ACTUALIZA-COMAREA                       06370700
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 06370800
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      06370900
                   PERFORM 6000-FINAL                                   06371000
               END-IF                                                   06371100
           END-IF                                                       06371200
           .                                                            06371300
      ************************ FIN DE 1400-INVOCA-RUT-BCRGTP05          06371400
      **************                                                    06371500
       3000-PROCESO.                                                    07190000
      **************                                                    07191000
      ******************************************************************07192000
      * PROCESAMIENTO DEL PROGRAMA                                     *07210000
      ******************************************************************07211000
                                                                        07230000
           EVALUATE TI-TR02-TRANS-EXTENDIDA                             07240000
              WHEN WS-CT-320                                            07250000
                   PERFORM 3100-TRANS-ORDINARIAS                        07260000
                                                                        07261000
              WHEN WS-CT-325                                            07270000
                   PERFORM 3400-PAGO-A-CUENTA-TCRE                      07280000
                                                                        07281000
              WHEN OTHER                                                07290000
      *            OBTENER MENSAJE PARA CCE                             07371000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  07372000
                                                                        07373000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  07374000
                   SET  TI-CF06-88-RECH        TO TRUE                  07375000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 07376000
                                              WS-TEMP-XX                07377000
                                              WS-CODMSG-ESTRUCTURA(1: 2)07378000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 07379000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07379100
                   MOVE WS-CT-1006         TO WS-CT-NUMER               07379200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  07379300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         07379400
                                                                        07379500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 07379600
                                                                        07379700
      *            OBTENER MENSAJE INTERNO                              07379800
                   MOVE WS-CODMSG-ESTRUCTURA                            07379900
                                           TO WS-COD-ERROR-07           07380000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                07380100
                                                                        07380200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        07380300
                                                                        07380400
                                                                        07380500
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 07380600
                   PERFORM 5600-ACTUALIZA-COMAREA                       07380700
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      07380800
                   PERFORM 6000-FINAL                                   07380900
           END-EVALUATE                                                 07381000
           .                                                            07381100
      ************************ FIN DE 3000-PROCESO                      07382000
      ***********************                                           07383000
       3100-TRANS-ORDINARIAS.                                           07400000
      ***********************                                           07401000
      ******************************************************************07402000
      * PROCESAMIENTO DE TRANS-ORDINARIAS                              *07420000
      ******************************************************************07421000
                                                                        07440000
           EVALUATE TI-TR02-CCI-CLI-BENEFICIA(16:1)                     07450000
              WHEN WS-CT-0                                              07460000
                 IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-604           07470000
      *             OBTENER MENSAJE PARA CCE                            07551000
                    MOVE SPACES                TO TI-CA15-I-O-MENSAJES  07552000
                                                                        07553000
                    SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  07554000
                    SET  TI-CF06-88-RECH       TO TRUE                  07555000
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 07556000
                                              WS-TEMP-XX                07557000
                                              WS-CODMSG-ESTRUCTURA(1: 2)07558000
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1009        TO TI-CF06-COD-RESP-AMPLIADO 07559000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07559100
                    MOVE WS-CT-1009        TO WS-CT-NUMER               07559200
                                              TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  07559300
                                              TI-TR02-ORIGEN-RESPUESTA          
                    PERFORM 6100-OBTENER-MENSAJE                        07559400
                                                                        07559500
                    MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 07559600
                                                                        07559700
      *             OBTENER MENSAJE INTERNO                             07559800
                    MOVE WS-CODMSG-ESTRUCTURA                           07559900
                                           TO WS-COD-ERROR-07           07560000
                    MOVE WS-PROGRAM-ID     TO WS-PROGRAM                07560100
                                                                        07560200
                    MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        07560300
                                                                        07560400
                                                                        07560500
                    PERFORM 5500-ACTUALIZA-MASTER-TRANSF                07560600
                    PERFORM 5600-ACTUALIZA-COMAREA                      07560700
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     07560800
                    PERFORM 6000-FINAL                                  07560900
                                                                        07561000
                 END-IF                                                 07562000
      *                                                                 07570000
              WHEN WS-CT-1                                              07580000
                 IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-840           07590000
      *             OBTENER MENSAJE PARA CCE                            07671000
                    MOVE SPACES                TO TI-CA15-I-O-MENSAJES  07672000
                                                                        07673000
                    SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  07674000
                    SET  TI-CF06-88-RECH       TO TRUE                  07675000
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 07676000
                                              WS-TEMP-XX                07677000
                                              WS-CODMSG-ESTRUCTURA(1: 2)07678000
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1009        TO TI-CF06-COD-RESP-AMPLIADO 07679000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07679100
                    MOVE WS-CT-1009        TO WS-CT-NUMER               07679200
                                              TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  07679300
                                              TI-TR02-ORIGEN-RESPUESTA          
                    PERFORM 6100-OBTENER-MENSAJE                        07679400
                                                                        07679500
                    MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 07679600
                                                                        07679700
      *             OBTENER MENSAJE INTERNO                             07679800
                    MOVE WS-CODMSG-ESTRUCTURA                           07679900
                                           TO WS-COD-ERROR-07           07680000
                    MOVE WS-PROGRAM-ID     TO WS-PROGRAM                07680100
                                                                        07680200
                    MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        07680300
                                                                        07680400
                    PERFORM 5500-ACTUALIZA-MASTER-TRANSF                07680600
                    PERFORM 5600-ACTUALIZA-COMAREA                      07680700
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     07680800
                    PERFORM 6000-FINAL                                  07680900
                                                                        07681000
                 END-IF                                                 07682000
      *                                                                 07690000
              WHEN OTHER                                                07700000
      *          OBTENER MENSAJE PARA CCE                               07781000
                 MOVE SPACES               TO TI-CA15-I-O-MENSAJES      07782000
                                                                        07783000
                 SET  TI-CA15-I-RC-APP-CCE TO TRUE                      07784000
                 SET  TI-CF06-88-RECH      TO TRUE                      07785000
                 MOVE WS-CT-05             TO TI-CF06-RESPONSE-CODE-CCE 07786000
                                              WS-TEMP-XX                07787000
                                              WS-CODMSG-ESTRUCTURA(1: 2)07788000
                                              TI-TR02-RESPONSE-CODE-CCE         
                 MOVE WS-CT-1009           TO TI-CF06-COD-RESP-AMPLIADO 07789000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07789100
                 MOVE WS-CT-1009           TO WS-CT-NUMER               07789200
                                              TI-TR02-COD-RESP-AMPLIADO         
                 MOVE WS-CT-001            TO TI-CF06-ORIGEN-RESPUESTA  07789300
                                              TI-TR02-ORIGEN-RESPUESTA          
                 PERFORM 6100-OBTENER-MENSAJE                           07789400
                                                                        07789500
                 MOVE WS-MENSAJE-TXT       TO TI-CF06-MENSAJE-RESPUESTA 07789600
                                                                        07789700
      *          OBTENER MENSAJE INTERNO                                07789800
                 MOVE WS-CODMSG-ESTRUCTURA                              07789900
                                           TO WS-COD-ERROR-07           07790000
                 MOVE WS-PROGRAM-ID        TO WS-PROGRAM                07790100
                                                                        07790200
                 MOVE WS-MENSAJE-TXT       TO WS-MENSAJE-TXT-EVE        07790300
                                                                        07790400
                 PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   07790500
                 PERFORM 5600-ACTUALIZA-COMAREA                         07790600
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        07790700
                 PERFORM 6000-FINAL                                     07790800
                                                                        07790900
           END-EVALUATE                                                 07792000
      *                                                                 07800000
           MOVE WS-CT-4           TO DGC-IND-CLAVE                      07810000
           IF TI-TR02-CCI-CLI-BENEFICIA(7:1) = WS-CT-0                  07820000
              MOVE 'CTE'          TO DGC-GLS-SERVICIO                   07830000
              STRING TI-TR02-CCI-CLI-BENEFICIA(4:3)                     07840000
                     WS-CT-0                                            07850000
                     TI-TR02-CCI-CLI-BENEFICIA(9:10)                    07860000
                     DELIMITED BY SIZE INTO DGC-GLS-CLAVE               07870000
              END-STRING                                                07880000
           ELSE                                                         07890000
              MOVE 'AHO'       TO DGC-GLS-SERVICIO                      07900000
              STRING TI-TR02-CCI-CLI-BENEFICIA(4:3)                     07910000
                     TI-TR02-CCI-CLI-BENEFICIA(8:11)                    07920000
                     DELIMITED BY SIZE INTO DGC-GLS-CLAVE               07930000
              END-STRING                                                07940000
           END-IF                                                       07950000
           MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     07960000
           PERFORM 4155-HOMOLOGA-DOC                                    07970000
           MOVE WS-TIPO-DOC-ORD-HOMOL    TO TI-CF06-TIP-DOC-CLI-ORIG    07971000
      *                                                                 07980000
           EXEC CICS LINK    PROGRAM(WS-RTN-SGCPPDGC)                   07990000
                             COMMAREA(SGCWGDGC)                         08000000
                             LENGTH(LENGTH OF SGCWGDGC)                 08010000
                             RESP(WS-RESP)                              08020000
                             END-EXEC                                   08030000
      *                                                                 08040000
           IF DGC-CRETORNO(1) = WS-CT-0000                              08050000
              MOVE WS-CT-1      TO IND                                  08060000
              MOVE 0            TO WS-CONTA                             08070000
              PERFORM UNTIL IND > 5 OR DGC-NUM-ICLI(IND) = SPACES       08080000
                PERFORM 3700-FORMATEAR-DOCUMENTO                        08090000
      *         IF  DGC-NUM-ICLI (IND) = TI-TR02-NRO-DOC-CLI-ORIG(1:8)  08100000
      *             AND DGC-IND-ICLI (IND) = WS-TIPO-DOC-ORD-HOMOL      08110000
      *             MOVE WS-CT-6             TO IND                     08120000
      *             SET  WS-ENCONTRADO-SI    TO TRUE                    08130000
      *             STRING WS-CT-SPACE4                                 08140000
      *                    DGC-NUM-ICLI(IND)                            08150000
      *                    DGC-IND-ICLI(IND)                            08160000
      *                    DGC-GLS-ICLI(IND)                            08170000
      *                    DELIMITED BY SIZE INTO WS-IDC                08180000
      *             END-STRING                                          08190000
      *         ELSE                                                    08200000
      *            IF  WS-TIPO-DOC-ORD-HOMOL = WS-CT-6                  08210000
      *                IF  DGC-COD-IRUC (IND)                           08220000
      *                               = TI-TR02-NRO-DOC-CLI-ORIG(1:11)  08221000
      *                    MOVE WS-CT-6              TO IND             08230000
      *                    SET WS-ENCONTRADO-SI      TO TRUE            08240000
      *                    STRING WS-CT-SPACE4                          08250000
      *                           DGC-NUM-ICLI(IND)                     08260000
      *                           DGC-IND-ICLI(IND)                     08270000
      *                           DGC-GLS-ICLI(IND)                     08280000
      *                           DELIMITED BY SIZE INTO WS-IDC         08290000
      *                    END-STRING                                   08300000
      *                END-IF                                           08310000
      *            END-IF                                               08320000
      *         END-IF                                                  08330000
                                                                        08331000
                EVALUATE WS-TIPO-DOC-ORD-HOMOL                          08331100
                  WHEN "6"                                              08331200
                      IF  DGC-COD-IRUC(IND)  =                          08331300
                                          TI-TR02-NRO-DOC-CLI-ORIG(1:11)08331400
                          SET WS-ENCONTRADO-SI      TO TRUE             08331600
                          STRING WS-CT-SPACE4                           08331700
                                 DGC-NUM-ICLI(IND)                      08331800
                                 DGC-IND-ICLI(IND)                      08331900
                                 DGC-GLS-ICLI(IND)                      08332000
                                 DELIMITED BY SIZE INTO WS-IDC          08332100
                          END-STRING                                    08332200
                          MOVE WS-CT-6              TO IND              08332300
                                                                        08332400
                      END-IF                                            08332500
                                                                        08332600
                  WHEN "3"                                              08332700
                  WHEN "4"                                              08332800
                      MOVE SPACES              TO WS-DOC-ORD-TMP        08332900
                      MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        08333000
                      PERFORM 3900-REORDENAR-DOCUMENTO                  08333100
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    08333200
                                                                        08333300
                      MOVE SPACES              TO WS-DOC-ORD-TMP        08333400
                      MOVE TI-TR02-NRO-DOC-CLI-ORIG                     08333500
                                               TO WS-DOC-ORD-TMP        08333600
                      PERFORM 3900-REORDENAR-DOCUMENTO                  08333700
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        08333800
                                                                        08333900
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 08334000
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  08334100
                         SET  WS-ENCONTRADO-SI    TO TRUE               08334200
                         STRING WS-CT-SPACE4                            08334500
                                DGC-NUM-ICLI(IND)                       08334600
                                DGC-IND-ICLI(IND)                       08334700
                                DGC-GLS-ICLI(IND)                       08334800
                                DELIMITED BY SIZE INTO WS-IDC           08334900
                         END-STRING                                     08335000
                         MOVE WS-CT-6             TO IND                08335100
                                                                        08335200
                      END-IF                                            08335300
                                                                        08335400
                  WHEN OTHER                                            08335500
                      IF DGC-NUM-ICLI(IND) =                            08335600
                                           TI-TR02-NRO-DOC-CLI-ORIG(1:8)08335700
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  08335800
                         SET  WS-ENCONTRADO-SI    TO TRUE               08335900
                         STRING WS-CT-SPACE4                            08336000
                                DGC-NUM-ICLI(IND)                       08336100
                                DGC-IND-ICLI(IND)                       08336200
                                DGC-GLS-ICLI(IND)                       08336300
                                DELIMITED BY SIZE INTO WS-IDC           08336400
                         END-STRING                                     08336500
                         MOVE WS-CT-6             TO IND                08336600
                                                                        08336700
                      END-IF                                            08336800
                                                                        08336900
                END-EVALUATE                                            08337000
                                                                        08338000
                ADD WS-CT-1N      TO IND                                08340000
              END-PERFORM                                               08350000
              IF  WS-ENCONTRADO-NO                                      08360000
                  STRING WS-CT-SPACE4                                   08370000
                         DGC-NUM-ICLI(1)                                08380000
                         DGC-IND-ICLI(1)                                08390000
                         DGC-GLS-ICLI(1)                                08400000
                         DELIMITED BY SIZE INTO WS-IDC                  08410000
                  END-STRING                                            08420000
              END-IF                                                    08430000
              MOVE WS-IDC                     TO TI-CF06-IDC-BEN        08431000
           ELSE                                                         08440000
             MOVE DGC-CRETORNO(1) TO WS-DGC-CRETORNO                    08450000
             EVALUATE WS-DGC-CRETORNO                                   08460000
                WHEN WS-CT-0001                                         08470000
                WHEN WS-CT-0002                                         08480000
                WHEN WS-CT-0003                                         08490000
                WHEN WS-CT-0009                                         08500000
      *            OBTENER MENSAJE PARA CCE                             08591000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08592000
                                                                        08593000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08594000
                   SET  TI-CF06-88-RECH        TO TRUE                  08595000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08596000
                                              WS-TEMP-XX                08597000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08598000
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)08599100
      *            MOVE WS-CT-1007         TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08599300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08599400
                                                                        08599500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08599600
                                                                        08599700
      *            OBTENER MENSAJE INTERNO                              08599800
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08599900
                                              WS-COD-ERROR-07           08600000
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08600100
                                              WS-PROGRAM                08600200
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08600300
                                              WS-MENSAJE-TXT-EVE        08600400
                                                                        08600500
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08600900
                   PERFORM 5600-ACTUALIZA-COMAREA                       08601000
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      08601100
                   PERFORM 6000-FINAL                                   08601200
                                                                        08601300
                WHEN WS-CT-2002                                         08602000
                WHEN WS-CT-2008                                         08610000
      *            OBTENER MENSAJE PARA CCE                             08620000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08630000
                                                                        08640000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08650000
                   SET  TI-CF06-88-RECH        TO TRUE                  08660000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08670000
                                              WS-TEMP-XX                08680000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08690000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO 08700000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08710000
                   MOVE WS-CT-1002         TO WS-CT-NUMER               08711000
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08711100
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08711200
                                                                        08711300
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08711400
                                                                        08711500
      *            OBTENER MENSAJE INTERNO                              08711600
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08711700
                                              WS-COD-ERROR-07           08711800
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08711900
                                              WS-PROGRAM                08712000
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08712100
                                              WS-MENSAJE-TXT-EVE        08712200
                                                                        08712300
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08712400
                   PERFORM 5600-ACTUALIZA-COMAREA                       08712500
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      08712600
                   PERFORM 6000-FINAL                                   08712700
                                                                        08712800
                WHEN OTHER                                              08713000
      *            OBTENER MENSAJE PARA CCE                             08801000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08802000
                                                                        08803000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08804000
                   SET  TI-CF06-88-RECH        TO TRUE                  08805000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08806000
                                              WS-TEMP-XX                08807000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08808000
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)08809100
      *            MOVE WS-CT-1008         TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08809300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08809400
                                                                        08809500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08809600
                                                                        08809700
      *            OBTENER MENSAJE INTERNO                              08809800
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08809900
                                              WS-COD-ERROR-07           08810000
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08810100
                                              WS-PROGRAM                08810200
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08810300
                                              WS-MENSAJE-TXT-EVE        08810400
                                                                        08810500
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08810600
                   PERFORM 5600-ACTUALIZA-COMAREA                       08810700
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      08810800
                   PERFORM 6000-FINAL                                   08810900
                                                                        08811000
             END-EVALUATE                                               08812000
           END-IF                                                       08820000
      *                                                                 08830000
           MOVE 'CTPB'           TO IPB-COD-INTR                        08840000
           MOVE 'TPB'            TO IPB-COD-TBL                         08850000
           MOVE 001              TO IPB-NUM-REQ                         08860000
           MOVE DGC-TIO-AUX(1)   TO IPB-COD-REG6(IPB-NUM-REQ)           08870000
           MOVE SPACES           TO IPB-COD-REG2(IPB-NUM-REQ).          08880000
      *                                                                 08890000
           EXEC CICS LINK PROGRAM (WS-RTN-TABPQTPB)                     08900000
                          COMMAREA(TABWGTPB)                            08910000
                          LENGTH  (LENGTH OF TABWGTPB)                  08920000
                          RESP    (WS-RESP)                             08930000
           END-EXEC                                                     08940000
      *                                                                 08950000
           IF WS-RESP EQUAL DFHRESP(NORMAL)                             09000000
              IF OPB-COD-RETO  = 'CT0000'                               09010000
                 IF OPB-GLS-RETO1 = '0'                                 09020000
                    CONTINUE                                            09030000
                 ELSE                                                   09040000
      *             OBTENER MENSAJE PARA CCE                            09141000
                    MOVE SPACES                TO TI-CA15-I-O-MENSAJES  09142000
                                                                        09143000
                    SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  09144000
                    SET  TI-CF06-88-RECH       TO TRUE                  09145000
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 09146000
                                              WS-TEMP-XX                09147000
                                              WS-CODMSG-ESTRUCTURA(1: 2)09148000
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO 09149000
                                              WS-CODMSG-ESTRUCTURA(3: 4)09149100
                    MOVE WS-CT-1006        TO WS-CT-NUMER               09149200
                                              TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  09149300
                                              TI-TR02-ORIGEN-RESPUESTA          
                    PERFORM 6100-OBTENER-MENSAJE                        09149400
                                                                        09149500
                    MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 09149600
                                                                        09149700
      *             OBTENER MENSAJE INTERNO                             09149800
                    MOVE WS-CODMSG-ESTRUCTURA                           09149900
                                           TO WS-COD-ERROR-07           09150000
                    MOVE WS-PROGRAM-ID     TO WS-PROGRAM                09150100
                                                                        09150200
                    MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        09150300
                                                                        09150400
                                                                        09150500
                    PERFORM 5500-ACTUALIZA-MASTER-TRANSF                09150600
                    PERFORM 5600-ACTUALIZA-COMAREA                      09150700
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     09150800
                    PERFORM 6000-FINAL                                  09150900
                 END-IF                                                 09151000
              ELSE                                                      09160000
      *          OBTENER MENSAJE PARA CCE                               09261000
                 MOVE SPACES                TO TI-CA15-I-O-MENSAJES     09262000
                                                                        09263000
                 SET  TI-CA15-I-RC-APP-CCE  TO TRUE                     09264000
                 SET  TI-CF06-88-RECH       TO TRUE                     09265000
                 MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE    09266000
                                           WS-TEMP-XX                   09267000
                                           WS-CODMSG-ESTRUCTURA(1: 2)   09268000
                                           TI-TR02-RESPONSE-CODE-CCE            
                 MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO    09269000
                                           WS-CODMSG-ESTRUCTURA(3: 4)   09269100
                 MOVE WS-CT-1006        TO WS-CT-NUMER                  09269200
                                           TI-TR02-COD-RESP-AMPLIADO            
                 MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA     09269300
                                           TI-TR02-ORIGEN-RESPUESTA             
                 PERFORM 6100-OBTENER-MENSAJE                           09269400
                                                                        09269500
                 MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA    09269600
                                                                        09269700
      *          OBTENER MENSAJE INTERNO                                09269800
                 MOVE WS-CODMSG-ESTRUCTURA                              09269900
                                        TO WS-COD-ERROR-07              09270000
                 MOVE WS-PROGRAM-ID     TO WS-PROGRAM                   09270100
                                                                        09270200
                 MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE           09270300
                                                                        09270400
                                                                        09270500
                 PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   09270600
                 PERFORM 5600-ACTUALIZA-COMAREA                         09270700
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        09270800
                 PERFORM 6000-FINAL                                     09270900
              END-IF                                                    09271000
           ELSE                                                         09280000
      *       OBTENER MENSAJE PARA CCE                                  09491000
              MOVE SPACES              TO TI-CA15-I-O-MENSAJES          09492000
                                                                        09493000
              SET  TI-CA15-I-RC-APP-CCE    TO TRUE                      09494000
              SET  TI-CF06-88-RECH         TO TRUE                      09495000
              MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE         09496000
                                      WS-TEMP-XX                        09497000
                                      WS-CODMSG-ESTRUCTURA(1: 2)        09498000
                                      TI-TR02-RESPONSE-CODE-CCE                 
              MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO         09499000
                                      WS-CODMSG-ESTRUCTURA(3: 4)        09499100
              MOVE WS-CT-1021      TO WS-CT-NUMER                       09499200
                                      TI-TR02-COD-RESP-AMPLIADO                 
              MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA          09499300
                                      TI-TR02-ORIGEN-RESPUESTA                  
              PERFORM 6100-OBTENER-MENSAJE                              09499400
                                                                        09499500
              MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA         09499600
                                                                        09499700
      *       OBTENER MENSAJE INTERNO                                   09499800
              MOVE OPB-COD-RETO    TO TI-CF06-CODMSG-ESTRUCT            09499900
                                      WS-COD-ERROR-07                   09500000
              MOVE WS-RTN-TABPQTPB TO TI-CF06-PRGNOM                    09500100
                                      WS-PROGRAM                        09500200
              MOVE OPB-GLS-RETO    TO TI-CF06-TXTMSG                    09500300
                                      WS-MENSAJE-TXT-EVE                09500400
                                                                        09500500
              PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      09500600
              PERFORM 5600-ACTUALIZA-COMAREA                            09500700
              PERFORM 5700-GRABAR-LOG-EVENTOS                           09500800
              PERFORM 6000-FINAL                                        09500900
           END-IF                                                       09502000
      *                                                                 09510000
           INSPECT RG-CA10-I-INPUT-CANAL-HEADER                         09520000
                   REPLACING ALL HIGH-VALUES BY SPACES                  09530000
           INSPECT RG-CA10-I-INPUT-CANAL-HEADER                         09540000
                   REPLACING ALL LOW-VALUES BY SPACES                   09550000
           INITIALIZE RG-CA10-I-INPUT-CANAL-HEADER                      09560000
                      REPLACING  NUMERIC DATA BY ZEROES                 09570000
                                 ALPHANUMERIC DATA BY SPACES            09580000
      *                                                                 09590000
           INSPECT OQ-TR27-I-TRAMA                                      09600000
                   REPLACING ALL HIGH-VALUES BY SPACES                  09610000
           INSPECT OQ-TR27-I-TRAMA                                      09620000
                   REPLACING ALL LOW-VALUES BY SPACES                   09630000
           INITIALIZE OQ-TR27-I-TRAMA                                   09640000
                      REPLACING  NUMERIC DATA BY ZEROES                 09650000
                                 ALPHANUMERIC DATA BY SPACES            09660000
      *                                                                 09670000
      * CARGA CABECERA ORQUESTADOR                                      09680000
           PERFORM 5000-CARGA-CABECERA                                  09690000
      *                                                                 09700000
      *                                                                 09710000
           PERFORM 5100-CARGA-DETALLES                                  09720000
      *                                                                 09730000
      * EXTRAE NOMBRE CORTO DE PARAMETROS.                              09740000
      *                                                                 09750000
           MOVE SPACES                       TO TI-CF01-KEY04           09760000
           MOVE '04'                         TO TI-CF01-KEY04-TIP-PRM   09770000
           MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)  TO TI-CF01-KEY04-BANCOS    09780000
           PERFORM 4100-EXTRAE-VALOR-PARAM                              09790000
      *                                                                 09800000
           STRING 'TRANSF.BCO.'                                         09810000
                TI-CF01-BCOS-NOMBRE-CORTO                               09820000
                DELIMITED BY SIZE INTO OQ-TR27-I-A-GLOSA1               09830000
           END-STRING                                                   09840000
      * NO COBRA COMISION AHORROS/CTACTE.                               09850000
           MOVE 'CCE'                  TO OQ-TR27-I-A-CAUSAL-TC         09860000
           MOVE ZEROS                  TO WS-SOLES WS-CENTI             09870000
           MOVE SPACES                 TO WS-SIGNO                      09880000
           MOVE '.'                    TO WS-PUNTO                      09890000
           MOVE ZEROS                  TO WS-SOLES(2:13)                09900000
           MOVE ZEROS                  TO WS-CENTI(1:2)                 09910000
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-A-IMP-COM-TC        09920000
           MOVE SPACES                 TO OQ-TR27-I-A-FLG-COMISION-TC   09930000
      *                                                                 09940000
           MOVE ZEROS                  TO WS-SOLES WS-CENTI             09950000
           MOVE SPACES                 TO WS-SIGNO                      09960000
           MOVE '.'                    TO WS-PUNTO                      09970000
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-A-IMP-COM-TC        09980000
           MOVE SPACES                 TO OQ-TR27-I-A-NRO-CHQ           09990000
           MOVE 'PCTC'                 TO OQ-TR27-I-A-TIPO-ABONO-TC     10000000
           MOVE 'CTAD'                 TO OQ-TR27-I-A-COD-ABONO         10010000
      *                                                                 10020000
           EVALUATE TI-TR02-CCI-CLI-BENEFICIA(7:1)                      10030000
             WHEN WS-CTN-0                                              10040000
      *         GENERA NUMERO CTA.CTE                                   10060000
                INITIALIZE             OQ-TR27-I-A-NRO-MEDIO            10070000
                MOVE WS-0000000     TO OQ-TR27-I-A-NRO-MEDIO(1:7)       10080000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(04:3) TO                 10090000
                                       OQ-TR27-I-A-NRO-MEDIO(8:3)       10100000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(09:7) TO                 10110000
                                       OQ-TR27-I-A-NRO-MEDIO(11:7)      10120000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(16:1) TO                 10130000
                                       OQ-TR27-I-A-NRO-MEDIO(18:1)      10140000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(17:2) TO                 10150000
                                       OQ-TR27-I-A-NRO-MEDIO(19:2)      10160000
      *                                                                 10170000
                IF TI-TR02-INDI-MISMO-CLIENTE = WS-CT-M                 10180000
                   MOVE '03'           TO TI-CF01-KEY03-TIP-PRM         10190000
                   MOVE '009'          TO TI-CF01-KEY03-CTABL           10200000
                   MOVE 'ACTEI'        TO TI-CF01-KEY03-DTABL           10210000
                   PERFORM 4100-EXTRAE-VALOR-PARAM                      10220000
                   MOVE TI-CF01-DTBL-VALOR(1:4) TO OQ-TR27-I-A-COD-UTC  10230000
                ELSE                                                    10240000
                   MOVE '03'           TO TI-CF01-KEY03-TIP-PRM         10250000
                   MOVE '009'          TO TI-CF01-KEY03-CTABL           10260000
                   MOVE 'ACTEA'        TO TI-CF01-KEY03-DTABL           10270000
                   PERFORM 4100-EXTRAE-VALOR-PARAM                      10280000
                   MOVE TI-CF01-DTBL-VALOR(1:4) TO OQ-TR27-I-A-COD-UTC  10290000
                END-IF                                                  10300000
      *                                                                 10310000
             WHEN WS-CT-1N                                              10320000
      * GENERA NUMERO CTA.AHORRO                                        10330000
                INITIALIZE        OQ-TR27-I-A-NRO-MEDIO                 10340000
                MOVE WS-000000 TO OQ-TR27-I-A-NRO-MEDIO(1:6)            10350000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(04:3) TO                 10360000
                                       OQ-TR27-I-A-NRO-MEDIO(7:3)       10370000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(08:8) TO                 10380000
                                       OQ-TR27-I-A-NRO-MEDIO(10:8)      10390000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(16:1) TO                 10400000
                                       OQ-TR27-I-A-NRO-MEDIO(18:1)      10410000
                MOVE TI-TR02-CCI-CLI-BENEFICIA(17:2) TO                 10420000
                                       OQ-TR27-I-A-NRO-MEDIO(19:2)      10430000
      *                                                                 10440000
                IF TI-TR02-INDI-MISMO-CLIENTE = 'M'                     10450000
                   MOVE '03'           TO TI-CF01-KEY03-TIP-PRM         10460000
                   MOVE '009'          TO TI-CF01-KEY03-CTABL           10470000
                   MOVE 'AAHOI'        TO TI-CF01-KEY03-DTABL           10480000
                   PERFORM 4100-EXTRAE-VALOR-PARAM                      10490000
                   MOVE TI-CF01-DTBL-VALOR(1:4) TO OQ-TR27-I-A-COD-UTC  10500000
                ELSE                                                    10510000
                   MOVE '03'           TO TI-CF01-KEY03-TIP-PRM         10520000
                   MOVE '009'          TO TI-CF01-KEY03-CTABL           10530000
                   MOVE 'AAHOA'        TO TI-CF01-KEY03-DTABL           10540000
                   PERFORM 4100-EXTRAE-VALOR-PARAM                      10550000
                   MOVE TI-CF01-DTBL-VALOR(1:4) TO OQ-TR27-I-A-COD-UTC  10560000
                END-IF                                                  10570000
      *                                                                 10580000
             WHEN OTHER                                                 10590000
      *         OBTENER MENSAJE PARA CCE                                10671000
                MOVE SPACES                TO TI-CA15-I-O-MENSAJES      10672000
                                                                        10673000
                SET  TI-CA15-I-RC-APP-CCE  TO TRUE                      10674000
                SET  TI-CF06-88-RECH       TO TRUE                      10675000
                MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE     10676000
                                          WS-TEMP-XX                    10677000
                                          WS-CODMSG-ESTRUCTURA(1: 2)    10678000
                                          TI-TR02-RESPONSE-CODE-CCE             
                MOVE WS-CT-1016        TO TI-CF06-COD-RESP-AMPLIADO     10679000
                                          WS-CODMSG-ESTRUCTURA(3: 4)    10679100
                MOVE WS-CT-1016        TO WS-CT-NUMER                   10679200
                                          TI-TR02-COD-RESP-AMPLIADO             
                MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA      10679300
                                          TI-TR02-ORIGEN-RESPUESTA              
                PERFORM 6100-OBTENER-MENSAJE                            10679400
                                                                        10679500
                MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA     10679600
                                                                        10679700
      *         OBTENER MENSAJE INTERNO                                 10679800
                MOVE WS-CODMSG-ESTRUCTURA                               10679900
                                       TO WS-COD-ERROR-07               10680000
                MOVE WS-PROGRAM-ID     TO WS-PROGRAM                    10680100
                                                                        10680200
                MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE            10680300
                                                                        10680400
                PERFORM 5500-ACTUALIZA-MASTER-TRANSF                    10680600
                PERFORM 5600-ACTUALIZA-COMAREA                          10680700
                PERFORM 5700-GRABAR-LOG-EVENTOS                         10680800
                PERFORM 6000-FINAL                                      10680900
           END-EVALUATE                                                 10681000
      *                                                                 10690000
           EXEC CICS LINK PROGRAM(WS-BCOQTP10)                          10700000
                         COMMAREA(OQ-TR27-TRAMA-CANAL)                  10710000
                           LENGTH(LENGTH OF OQ-TR27-TRAMA-CANAL)        10720000
                             RESP(WS-RESP)                              10730000
           END-EXEC                                                     10740000
                                                                        10750000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        10921000
      *        OBTENER MENSAJE PARA CCE                                 10922000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      10923000
                                                                        10924000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      10925000
               SET  TI-CF06-88-RECH        TO TRUE                      10926000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 10927000
                                              WS-TEMP-XX                10928000
                                              WS-CODMSG-ESTRUCTURA(1: 2)10929000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 10929100
                                              WS-CODMSG-ESTRUCTURA(3: 4)10929200
               MOVE WS-CT-1021             TO WS-CT-NUMER               10929300
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  10929400
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             10929500
                                                                        10929600
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 10929700
               PERFORM 5600-ACTUALIZA-COMAREA                           10929800
                                                                        10930000
      *        OBTENER MENSAJE INTERNO                                  10930100
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      10930200
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      10930300
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    10930400
                                              WS-CODMSG-ESTRUCTURA      10930500
                                              WS-COD-ERROR-07           10930600
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            10930700
                                              WS-PROGRAM                10930800
               MOVE 'LINK'                 TO WS-VARMSG-FUN             10930900
               MOVE WS-BCOQTP10            TO WS-VARMSG-RSO             10931000
                                                                        10931100
               PERFORM 6100-OBTENER-MENSAJE                             10931200
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            10931300
                                              WS-MENSAJE-TXT-EVE        10931400
                                                                        10931500
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     10931600
               PERFORM 5700-GRABAR-LOG-EVENTOS                          10931800
               PERFORM 6000-FINAL                                       10931900
           ELSE                                                         10932000
               MOVE OQ-TR27-O-HDR      TO RG-CA10-O-OUTPUT-CANAL-HEADER 10932100
               EVALUATE RG-CA10-O-RCODE                                 10932200
                  WHEN 'OQ0000'                                         10932400
                       CONTINUE                                         10932500
                                                                        10932600
                  WHEN WS-CT-GN4904                                     10932700
      *                OBTENER MENSAJE PARA CCE                         10932800
                       MOVE SPACES             TO TI-CA15-I-O-MENSAJES  10932900
                                                                        10933000
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              10933100
                       SET  TI-CF06-88-RECH        TO TRUE              10933200
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 10933300
                                              WS-TEMP-XX                10933400
                                              WS-CODMSG-ESTRUCTURA(1: 2)10933500
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1001     TO TI-CF06-COD-RESP-AMPLIADO 10933600
                                              WS-CODMSG-ESTRUCTURA(3: 4)10933700
                       MOVE WS-CT-1001     TO WS-CT-NUMER               10933800
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  10933900
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     10934000
                                                                        10934100
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 10934200
                                                                        10934300
      *                OBTENER MENSAJE INTERNO                          10934400
                       MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT10934500
                                                  WS-COD-ERROR-07       10934600
                       MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM        10934700
                                                  WS-PROGRAM            10934800
                       MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG        10934900
                                                  WS-MENSAJE-TXT-EVE    10935000
                                                                        10935100
                       PERFORM 5500-ACTUALIZA-MASTER-TRANSF             10935200
                       PERFORM 5600-ACTUALIZA-COMAREA                   10935300
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  10935400
                       PERFORM 6000-FINAL                               10935500
                                                                        10935600
                                                                        10935700
                  WHEN OTHER                                            10935800
      *                OBTENER MENSAJE PARA CCE                         10935900
                       MOVE SPACES             TO TI-CA15-I-O-MENSAJES  10936000
                                                                        10936100
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              10936200
                       SET  TI-CF06-88-RECH        TO TRUE              10936300
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 10936400
                                              WS-TEMP-XX                10936500
                                              WS-CODMSG-ESTRUCTURA(1: 2)10936600
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 10936700
                                              WS-CODMSG-ESTRUCTURA(3: 4)10936800
                       MOVE WS-CT-1021     TO WS-CT-NUMER               10936900
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  10937000
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     10937100
                                                                        10937200
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 10937300
                                                                        10937400
      *                OBTENER MENSAJE INTERNO                          10937500
                       MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT10937600
                                                  WS-COD-ERROR-07       10937700
                       MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM        10937800
                                                  WS-PROGRAM            10937900
                       MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG        10938000
                                                  WS-MENSAJE-TXT-EVE    10938100
                                                                        10938200
                       PERFORM 5500-ACTUALIZA-MASTER-TRANSF             10938300
                       PERFORM 5600-ACTUALIZA-COMAREA                   10938400
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  10938500
                       PERFORM 6000-FINAL                               10938600
                                                                        10938700
               END-EVALUATE                                             10938800
           END-IF                                                       10938900
           .                                                            10939000
      ************************ FIN DE 3100-TRANS-ORDINARIAS             10939100
      *************************                                         10939200
       3400-PAGO-A-CUENTA-TCRE.                                         10940000
      *************************                                         10941000
      ******************************************************************10942000
      * PROCESAMIENTO DE 3400-PAGO-A-CUENTA-TCRE                       *10960000
      ******************************************************************10961000
                                                                        10962000
           INITIALIZE DGC-GLS-CLAVE                                     10980000
           MOVE WS-CT-4            TO DGC-IND-CLAVE                     10990000
           MOVE 'TCR'              TO DGC-GLS-SERVICIO                  11000000
      *                                                                 11010000
           PERFORM 3450-VALIDA-TARJETA                                  11020000
      *                                                                 11030000
           IF  VP-TIPO-PROD = 'A'                                       11040000
               MOVE TI-TR02-COD-TARJETA-CRED(6:15)                      11050000
                                           TO DGC-GLS-CLAVE(1:15)       11060000
               MOVE '0'                    TO DGC-GLS-CLAVE(16:1)       11070000
                                                                        11080000
           ELSE                                                         11090000
               MOVE TI-TR02-COD-TARJETA-CRED(5:16)                      11110100
                                           TO DGC-GLS-CLAVE(1:16)       11110200
                                                                        11110300
           END-IF                                                       11110400
                                                                        11110500
           MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     11111000
           PERFORM 4155-HOMOLOGA-DOC                                    11120000
           MOVE WS-TIPO-DOC-ORD-HOMOL      TO TI-CF06-TIP-DOC-CLI-ORIG  11121000
                                                                        11130000
           EXEC CICS LINK    PROGRAM(WS-RTN-SGCPPDGC)                   11131000
                             COMMAREA(SGCWGDGC)                         11132000
                             LENGTH(LENGTH OF SGCWGDGC)                 11133000
                             RESP(WS-RESP)                              11134000
                             END-EXEC                                   11135000
      *                                                                 11136000
           IF DGC-CRETORNO(1) = WS-CT-0000                              11137000
              MOVE WS-CT-1      TO IND                                  11138000
              MOVE 0            TO WS-CONTA                             11139000
              PERFORM UNTIL IND > 5 OR DGC-NUM-ICLI(IND) = SPACES       11139100
                PERFORM 3700-FORMATEAR-DOCUMENTO                        11139200
      *           IF  DGC-NUM-ICLI (IND) = TI-TR02-NRO-DOC-CLI-ORIG(1:8)11139300
      *               AND DGC-IND-ICLI (IND) = WS-TIPO-DOC-ORD-HOMOL    11139400
      *               MOVE WS-CT-6             TO IND                   11139500
      *               SET  WS-ENCONTRADO-SI    TO TRUE                  11139600
      *               STRING WS-CT-SPACE4                               11139700
      *                      DGC-NUM-ICLI(IND)                          11139800
      *                      DGC-IND-ICLI(IND)                          11139900
      *                      DGC-GLS-ICLI(IND)                          11140000
      *                      DELIMITED BY SIZE INTO WS-IDC              11140100
      *               END-STRING                                        11140200
      *           ELSE                                                  11140300
      *              IF  WS-TIPO-DOC-ORD-HOMOL = WS-CT-6                11140400
      *                  IF DGC-COD-IRUC (IND)                          11140500
      *                                 = TI-TR02-NRO-DOC-CLI-ORIG(1:11)11140600
      *                     MOVE WS-CT-6              TO IND            11140700
      *                     SET WS-ENCONTRADO-SI      TO TRUE           11140800
      *                     STRING WS-CT-SPACE4                         11140900
      *                            DGC-NUM-ICLI(IND)                    11141000
      *                            DGC-IND-ICLI(IND)                    11141100
      *                            DGC-GLS-ICLI(IND)                    11141200
      *                            DELIMITED BY SIZE INTO WS-IDC        11141300
      *                     END-STRING                                  11141400
      *                  END-IF                                         11141500
      *              END-IF                                             11141600
      *           END-IF                                                11141700
                EVALUATE WS-TIPO-DOC-ORD-HOMOL                          11141800
                  WHEN "6"                                              11141900
                      IF  DGC-COD-IRUC(IND)  =                          11142000
                                          TI-TR02-NRO-DOC-CLI-ORIG(1:11)11142100
                          SET WS-ENCONTRADO-SI      TO TRUE             11142200
                          STRING WS-CT-SPACE4                           11142300
                                 DGC-NUM-ICLI(IND)                      11142400
                                 DGC-IND-ICLI(IND)                      11142500
                                 DGC-GLS-ICLI(IND)                      11142600
                                 DELIMITED BY SIZE INTO WS-IDC          11142700
                          END-STRING                                    11142800
                          MOVE WS-CT-6              TO IND              11142900
                                                                        11143000
                      END-IF                                            11143100
                                                                        11143200
                  WHEN "3"                                              11143300
                  WHEN "4"                                              11143400
                      MOVE SPACES              TO WS-DOC-ORD-TMP        11143500
                      MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        11143600
                      PERFORM 3900-REORDENAR-DOCUMENTO                  11143700
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    11143800
                                                                        11143900
                      MOVE SPACES              TO WS-DOC-ORD-TMP        11144000
                      MOVE TI-TR02-NRO-DOC-CLI-ORIG                     11144100
                                               TO WS-DOC-ORD-TMP        11144200
                      PERFORM 3900-REORDENAR-DOCUMENTO                  11144300
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        11144400
                                                                        11144500
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 11144600
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  11144700
                         SET  WS-ENCONTRADO-SI    TO TRUE               11144800
                         STRING WS-CT-SPACE4                            11144900
                                DGC-NUM-ICLI(IND)                       11145000
                                DGC-IND-ICLI(IND)                       11145100
                                DGC-GLS-ICLI(IND)                       11145200
                                DELIMITED BY SIZE INTO WS-IDC           11145300
                         END-STRING                                     11145400
                         MOVE WS-CT-6             TO IND                11145500
                                                                        11145600
                      END-IF                                            11145700
                                                                        11145800
                  WHEN OTHER                                            11145900
                      IF DGC-NUM-ICLI(IND) =                            11146000
                                           TI-TR02-NRO-DOC-CLI-ORIG(1:8)11146100
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  11146200
                         SET  WS-ENCONTRADO-SI    TO TRUE               11146300
                         STRING WS-CT-SPACE4                            11146400
                                DGC-NUM-ICLI(IND)                       11146500
                                DGC-IND-ICLI(IND)                       11146600
                                DGC-GLS-ICLI(IND)                       11146700
                                DELIMITED BY SIZE INTO WS-IDC           11146800
                         END-STRING                                     11146900
                         MOVE WS-CT-6             TO IND                11147000
                                                                        11147100
                      END-IF                                            11147200
                                                                        11147300
                END-EVALUATE                                            11147400
                ADD WS-CT-1N      TO IND                                11147500
              END-PERFORM                                               11147600
                                                                        11147700
              IF  WS-ENCONTRADO-NO                                      11147800
                  STRING WS-CT-SPACE4                                   11147900
                         DGC-NUM-ICLI(1)                                11148000
                         DGC-IND-ICLI(1)                                11148100
                         DGC-GLS-ICLI(1)                                11148200
                         DELIMITED BY SIZE INTO WS-IDC                  11148300
                  END-STRING                                            11148400
              END-IF                                                    11148500
              MOVE WS-IDC                     TO TI-CF06-IDC-BEN        11148600
           ELSE                                                         11148700
             MOVE DGC-CRETORNO(1) TO WS-DGC-CRETORNO                    11148800
             EVALUATE WS-DGC-CRETORNO                                   11148900
                WHEN WS-CT-0001                                         11149000
                WHEN WS-CT-0002                                         11149100
                WHEN WS-CT-0003                                         11149200
                WHEN WS-CT-0009                                         11149300
      *            OBTENER MENSAJE PARA CCE                             11149400
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11149500
                                                                        11149600
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11149700
                   SET  TI-CF06-88-RECH        TO TRUE                  11149800
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11149900
                                              WS-TEMP-XX                11150000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11150100
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)11150300
      *            MOVE WS-CT-1007         TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11150500
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         11150600
                                                                        11150700
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11150800
                                                                        11150900
      *            OBTENER MENSAJE INTERNO                              11151000
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11151100
                                              WS-COD-ERROR-07           11151200
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11151300
                                              WS-PROGRAM                11151400
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11151500
                                              WS-MENSAJE-TXT-EVE        11151600
                                                                        11151700
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11151800
                   PERFORM 5600-ACTUALIZA-COMAREA                       11151900
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11152000
                   PERFORM 6000-FINAL                                   11152100
                                                                        11152200
                WHEN WS-CT-2002                                         11152300
                WHEN WS-CT-2008                                         11152400
      *            OBTENER MENSAJE PARA CCE                             11152500
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11152600
                                                                        11152700
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11152800
                   SET  TI-CF06-88-RECH        TO TRUE                  11152900
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11153000
                                              WS-TEMP-XX                11153100
                                              WS-CODMSG-ESTRUCTURA(1: 2)11153200
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO 11153300
                                              WS-CODMSG-ESTRUCTURA(3: 4)11153400
                   MOVE WS-CT-1002         TO WS-CT-NUMER               11153500
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11153600
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         11153700
                                                                        11153800
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11153900
                                                                        11154000
      *            OBTENER MENSAJE INTERNO                              11154100
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11154200
                                              WS-COD-ERROR-07           11154300
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11154400
                                              WS-PROGRAM                11154500
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11154600
                                              WS-MENSAJE-TXT-EVE        11154700
                                                                        11154800
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11154900
                   PERFORM 5600-ACTUALIZA-COMAREA                       11155000
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11155100
                   PERFORM 6000-FINAL                                   11155200
                                                                        11155300
                WHEN OTHER                                              11155400
      *            OBTENER MENSAJE PARA CCE                             11155500
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11155600
                                                                        11155700
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11155800
                   SET  TI-CF06-88-RECH        TO TRUE                  11155900
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11156000
                                              WS-TEMP-XX                11156100
                                              WS-CODMSG-ESTRUCTURA(1: 2)11156200
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)11156400
      *            MOVE WS-CT-1008         TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11156600
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         11156700
                                                                        11156800
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11156900
                                                                        11157000
      *            OBTENER MENSAJE INTERNO                              11157100
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11157200
                                              WS-COD-ERROR-07           11157300
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11157400
                                              WS-PROGRAM                11157500
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11157600
                                              WS-MENSAJE-TXT-EVE        11157700
                                                                        11157800
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11157900
                   PERFORM 5600-ACTUALIZA-COMAREA                       11158000
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11158100
                   PERFORM 6000-FINAL                                   11158200
                                                                        11158300
             END-EVALUATE                                               11158400
           END-IF                                                       11159000
           MOVE WS-CT-CTPB       TO IPB-COD-INTR                        12050000
           MOVE WS-CT-TPB        TO IPB-COD-TBL                         12060000
           MOVE 1                TO IPB-NUM-REQ                         12070000
           MOVE DGC-TIO-AUX(1)   TO IPB-COD-REG6(IPB-NUM-REQ)           12080000
           MOVE SPACES           TO IPB-COD-REG2(IPB-NUM-REQ)           12090000
      *                                                                 12100000
           EXEC CICS LINK PROGRAM (WS-RTN-TABPQTPB)                     12101000
                          COMMAREA(TABWGTPB)                            12102000
                          LENGTH  (LENGTH OF TABWGTPB)                  12103000
                          RESP    (WS-RESP)                             12104000
           END-EXEC                                                     12105000
      *                                                                 12106000
           IF WS-RESP EQUAL DFHRESP(NORMAL)                             12109200
              IF OPB-COD-RETO  = 'CT0000'                               12109300
                 IF OPB-GLS-RETO1 = '0'                                 12109400
                    CONTINUE                                            12109500
                 ELSE                                                   12109600
      *             OBTENER MENSAJE PARA CCE                            12109700
                    MOVE SPACES                TO TI-CA15-I-O-MENSAJES  12109800
                                                                        12109900
                    SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  12110000
                    SET  TI-CF06-88-RECH       TO TRUE                  12110100
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 12110200
                                              WS-TEMP-XX                12110300
                                              WS-CODMSG-ESTRUCTURA(1: 2)12110400
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO 12110500
                                              WS-CODMSG-ESTRUCTURA(3: 4)12110600
                    MOVE WS-CT-1006        TO WS-CT-NUMER               12110700
                                              TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  12110800
                                              TI-TR02-ORIGEN-RESPUESTA          
                    PERFORM 6100-OBTENER-MENSAJE                        12110900
                                                                        12111000
                    MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 12111100
                                                                        12111200
      *             OBTENER MENSAJE INTERNO                             12111300
                    MOVE WS-CODMSG-ESTRUCTURA                           12111400
                                           TO WS-COD-ERROR-07           12111500
                    MOVE WS-PROGRAM-ID     TO WS-PROGRAM                12111600
                                                                        12111700
                    MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        12111800
                                                                        12111900
                                                                        12112000
                    PERFORM 5500-ACTUALIZA-MASTER-TRANSF                12112100
                    PERFORM 5600-ACTUALIZA-COMAREA                      12112200
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     12112300
                    PERFORM 6000-FINAL                                  12112400
                 END-IF                                                 12112500
              ELSE                                                      12112600
      *          OBTENER MENSAJE PARA CCE                               12112700
                 MOVE SPACES                TO TI-CA15-I-O-MENSAJES     12112800
                                                                        12112900
                 SET  TI-CA15-I-RC-APP-CCE  TO TRUE                     12113000
                 SET  TI-CF06-88-RECH       TO TRUE                     12113100
                 MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE    12113200
                                           WS-TEMP-XX                   12113300
                                           WS-CODMSG-ESTRUCTURA(1: 2)   12113400
                                           TI-TR02-RESPONSE-CODE-CCE            
                 MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO    12113500
                                           WS-CODMSG-ESTRUCTURA(3: 4)   12113600
                 MOVE WS-CT-1006        TO WS-CT-NUMER                  12113700
                                           TI-TR02-COD-RESP-AMPLIADO            
                 MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA     12113800
                                           TI-TR02-ORIGEN-RESPUESTA             
                 PERFORM 6100-OBTENER-MENSAJE                           12113900
                                                                        12114000
                 MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA    12114100
                                                                        12114200
      *          OBTENER MENSAJE INTERNO                                12114300
                 MOVE WS-CODMSG-ESTRUCTURA                              12114400
                                        TO WS-COD-ERROR-07              12114500
                 MOVE WS-PROGRAM-ID     TO WS-PROGRAM                   12114600
                                                                        12114700
                 MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE           12114800
                                                                        12114900
                                                                        12115000
                 PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   12115100
                 PERFORM 5600-ACTUALIZA-COMAREA                         12115200
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        12115300
                 PERFORM 6000-FINAL                                     12115400
              END-IF                                                    12115500
           ELSE                                                         12115600
      *       OBTENER MENSAJE PARA CCE                                  12115700
              MOVE SPACES              TO TI-CA15-I-O-MENSAJES          12115800
                                                                        12115900
              SET  TI-CA15-I-RC-APP-CCE    TO TRUE                      12116000
              SET  TI-CF06-88-RECH         TO TRUE                      12116100
              MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE         12116200
                                      WS-TEMP-XX                        12116300
                                      WS-CODMSG-ESTRUCTURA(1: 2)        12116400
                                      TI-TR02-RESPONSE-CODE-CCE                 
              MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO         12116500
                                      WS-CODMSG-ESTRUCTURA(3: 4)        12116600
              MOVE WS-CT-1021      TO WS-CT-NUMER                       12116700
                                      TI-TR02-COD-RESP-AMPLIADO                 
              MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA          12116800
                                      TI-TR02-ORIGEN-RESPUESTA                  
              PERFORM 6100-OBTENER-MENSAJE                              12116900
                                                                        12117000
              MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA         12117100
                                                                        12117200
      *       OBTENER MENSAJE INTERNO                                   12117300
              MOVE OPB-COD-RETO    TO TI-CF06-CODMSG-ESTRUCT            12117400
                                      WS-COD-ERROR-07                   12117500
              MOVE WS-RTN-TABPQTPB TO TI-CF06-PRGNOM                    12117600
                                      WS-PROGRAM                        12117700
              MOVE OPB-GLS-RETO    TO TI-CF06-TXTMSG                    12117800
                                      WS-MENSAJE-TXT-EVE                12117900
                                                                        12118000
              PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      12118100
              PERFORM 5600-ACTUALIZA-COMAREA                            12118200
              PERFORM 5700-GRABAR-LOG-EVENTOS                           12118300
              PERFORM 6000-FINAL                                        12118400
           END-IF                                                       12118500
      *    CARGA CABECERA DE ORQUESTADOR                                12700000
           PERFORM 5000-CARGA-CABECERA                                  12710000
      *                                                                 12720000
           PERFORM 5100-CARGA-DETALLES                                  12730000
      *                                                                 12740000
           MOVE SPACES                     TO TI-CF01-KEY04             12750000
           MOVE '04'                       TO TI-CF01-KEY04-TIP-PRM     12760000
           MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)TO TI-CF01-KEY04-BANCOS      12770000
           PERFORM 4100-EXTRAE-VALOR-PARAM                              12780000
      *                                                                 12790000
           STRING  'PAGO A CTA.BCO.'                                    12800000
               TI-CF01-BCOS-NOMBRE-CORTO                                12810000
               DELIMITED BY SIZE INTO OQ-TR27-I-A-GLOSA1                12820000
           END-STRING                                                   12830000
      *                                                                 12840000
           MOVE ZEROES                 TO OQ-TR27-I-A-NRO-GLOSA         12850000
           MOVE SPACES                 TO OQ-TR27-I-A-COD-UTC           12860000
           MOVE 'PCTC'                 TO OQ-TR27-I-A-TIPO-ABONO-TC     12870000
           MOVE 'CCE'                  TO OQ-TR27-I-A-CAUSAL-TC         12880000
           MOVE '0000'                 TO OQ-TR27-I-A-FEXP-TC           12890000
           MOVE '0000'                 TO OQ-TR27-I-A-COD-UTC           12891000
           MOVE '000000000'            TO OQ-TR27-I-A-COD-ESTAB-TC      12900000
      *                                                                 12910000
           MOVE SPACES                 TO OQ-TR27-I-A-FLG-PAG-3ROS-TC   12920000
           MOVE SPACES                 TO OQ-TR27-I-A-NRO-PLAN-TC       12930000
           MOVE SPACES                 TO OQ-TR27-I-A-SEC-PLAN-TC       12940000
           MOVE 'TCRE'                 TO OQ-TR27-I-A-COD-ABONO         12950000
           MOVE TI-CF06-COD-MON        TO OQ-TR27-I-A-MON-MEDIO         12960000
      * IMPORTE ABONO TC                                                12970000
           MOVE ZEROS                  TO WS-SOLES WS-CENTI             12980000
           MOVE SPACES                 TO WS-SIGNO                      12990000
           MOVE TI-TR02-IMPORTE(1:10)  TO WS-SOLES(5:10)                13000000
           MOVE '.'                    TO WS-PUNTO                      13010000
           MOVE TI-TR02-IMPORTE(11:2)  TO WS-CENTI(1:2)                 13020000
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-IMP-OPE             13030000
      *                                                                 13040000
      * SI COBRA COMISION A TC.                                         13050000
           MOVE 'CCE'                  TO OQ-TR27-I-A-CAUSAL-TC         13060000
           MOVE ZEROS                  TO WS-SOLES WS-CENTI             13070000
           MOVE SPACES                 TO WS-SIGNO                      13080000
           MOVE '.'                    TO WS-PUNTO                      13090000
           MOVE TI-TR02-IMPORTE-COMISION(1:13) TO WS-SOLES(2:13)        13100000
           MOVE TI-TR02-IMPORTE-COMISION(14:2) TO WS-CENTI(1:2)         13110000
           MOVE 'TCRE'                 TO OQ-TR27-I-A-COD-ABONO         13120000
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-A-IMP-COM-TC        13130000
           MOVE 'S'                    TO OQ-TR27-I-A-FLG-COMISION-TC   13140000
      *                                                                 13150000
           IF  OQ-TR27-I-A-COD-FAM = WS-003                             13160000
               AND OQ-TR27-I-A-COD-PRO = WS-014                         13170000
      *        TC AMEX                                                  13180000
               INITIALIZE OQ-TR27-I-A-NRO-MEDIO                         13190000
               MOVE WS-0000            TO OQ-TR27-I-A-NRO-MEDIO(2:4)    13200000
               MOVE TI-TR02-COD-TARJETA-CRED(6:15)                      13210000
                                       TO OQ-TR27-I-A-NRO-MEDIO(6:15)   13220000
                                                                        13221000
           ELSE                                                         13230000
      *        TC VISA / MASTERCARD                                     13240000
               IF  OQ-TR27-I-A-COD-FAM = WS-003 AND                     13250000
                   (OQ-TR27-I-A-COD-PRO = WS-013 OR                     13260000
                   OQ-TR27-I-A-COD-PRO = WS-082)                        13270000
                   INITIALIZE OQ-TR27-I-A-NRO-MEDIO                     13280000
                   MOVE WS-000         TO OQ-TR27-I-A-NRO-MEDIO(2:3)    13290000
                   MOVE TI-TR02-COD-TARJETA-CRED(5:16)                  13300000
                                       TO OQ-TR27-I-A-NRO-MEDIO(5:16)   13310000
                                                                        13311000
              END-IF                                                    13320000
           END-IF                                                       13330000
      *                                                                 13340000
      *    IF  VP-TIPO-PROD = 'A'                                       13341000
      *        MOVE TI-TR02-COD-TARJETA-CRED (6:15)                     13342000
      *                            TO DGC-GLS-CLAVE(1:15)               13343000
      *        MOVE '0'            TO DGC-GLS-CLAVE(16:1)               13344000
      *    ELSE                                                         13345000
      *        MOVE TI-TR02-COD-TARJETA-CRED (5:16)                     13346000
      *                            TO DGC-GLS-CLAVE                     13347000
      *    END-IF                                                       13348000
           EXEC CICS LINK PROGRAM(WS-BCOQTP10)                          13350000
                         COMMAREA(OQ-TR27-TRAMA-CANAL)                  13360000
                           LENGTH(LENGTH OF OQ-TR27-TRAMA-CANAL)        13370000
                             RESP(WS-RESP)                              13380000
           END-EXEC                                                     13390000
      *                                                                 13400000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        13611000
      *        OBTENER MENSAJE PARA CCE                                 13612000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      13613000
                                                                        13614000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      13615000
               SET  TI-CF06-88-RECH        TO TRUE                      13616000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 13617000
                                              WS-TEMP-XX                13618000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13619000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 13619100
                                              WS-CODMSG-ESTRUCTURA(3: 4)13619200
               MOVE WS-CT-1021             TO WS-CT-NUMER               13619300
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  13619400
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             13619500
                                                                        13619600
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 13619700
               PERFORM 5600-ACTUALIZA-COMAREA                           13619800
                                                                        13619900
      *        OBTENER MENSAJE INTERNO                                  13620000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      13620100
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      13620200
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    13620300
                                              WS-CODMSG-ESTRUCTURA      13620400
                                              WS-COD-ERROR-07           13620500
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            13620600
                                              WS-PROGRAM                13620700
               MOVE 'LINK'                 TO WS-VARMSG-FUN             13620800
               MOVE WS-BCOQTP10            TO WS-VARMSG-RSO             13620900
                                                                        13621000
               PERFORM 6100-OBTENER-MENSAJE                             13621100
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            13621200
                                              WS-MENSAJE-TXT-EVE        13621300
                                                                        13621400
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     13621500
               PERFORM 5700-GRABAR-LOG-EVENTOS                          13621600
               PERFORM 6000-FINAL                                       13621700
           ELSE                                                         13621800
               MOVE OQ-TR27-O-HDR      TO RG-CA10-O-OUTPUT-CANAL-HEADER 13621900
               IF  RG-CA10-O-RCODE = 'OQ0000'                           13622000
                   CONTINUE                                             13622100
               ELSE                                                     13622200
      *            OBTENER MENSAJE PARA CCE                             13622300
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  13622400
                                                                        13622500
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  13622600
                   SET  TI-CF06-88-RECH        TO TRUE                  13622700
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 13622800
                                              WS-TEMP-XX                13622900
                                              WS-CODMSG-ESTRUCTURA(1: 2)13623000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 13623100
                                              WS-CODMSG-ESTRUCTURA(3: 4)13623200
                   MOVE WS-CT-1021         TO WS-CT-NUMER               13623300
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  13623400
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         13623500
                                                                        13623600
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 13623700
                                                                        13623800
      *            OBTENER MENSAJE INTERNO                              13623900
                   MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT    13624000
                                              WS-COD-ERROR-07           13624100
                   MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM            13624200
                                              WS-PROGRAM                13624300
                   MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG            13624400
                                              WS-MENSAJE-TXT-EVE        13624500
                                                                        13624600
                   PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 13624700
                   PERFORM 5600-ACTUALIZA-COMAREA                       13624800
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      13624900
                   PERFORM 6000-FINAL                                   13625000
               END-IF                                                   13625100
           END-IF                                                       13625200
           .                                                            13625300
      ************************ FIN DE 3400-PAGO-A-CUENTA-TCRE           13625400
      *********************                                             13626000
       3450-VALIDA-TARJETA.                                             13630000
      *********************                                             13640000
                                                                        13641000
           INITIALIZE VP-AREA-DATOS-N                                   13642000
                      RG-CA10-I-INPUT-CANAL-HEADER                      13643000
                      RG-CA10-O-OUTPUT-CANAL-HEADER.                    13644000
           MOVE 'VP28'                     TO RG-CA10-I-COD-INTERFAZ    13645000
           MOVE 'A'                        TO RG-CA10-I-CANAL-TIPO      13646000
           MOVE 'P'                        TO RG-CA10-I-CANAL-INST      13647000
           MOVE '1'                        TO RG-CA10-I-COD-INSTITUCION 13648000
           MOVE TI-CW03-CANAL              TO RG-CA10-I-CANAL-APL       13649000
           MOVE RG-CA05-O-0A-AMBIENTE      TO RG-CA10-I-CANAL-AMB       13649100
           MOVE ZEROS                      TO WS-NRO-OPERACION          13649200
           MOVE TI-TR02-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     13649300
           MOVE WS-NRO-OPERACION       TO RG-CA10-I-NRO-OPE-CANAL       13649400
           MOVE WS-CT-01               TO RG-CA10-I-VERSION             13649500
           MOVE WS-CT-0                TO RG-CA10-I-FLAG-EXT-OPE        13649600
           MOVE ZEROS                  TO RG-CA10-I-NRO-OPE-CANAL-A-EXT 13649700
           MOVE WS-HORA-INI            TO RG-CA10-I-HORA-CANAL          13649800
           MOVE WS-FECHA-INI           TO RG-CA10-I-FECHA-CANAL         13649900
           MOVE WS-CT-111              TO RG-CA10-I-SUCURSAL-OPERACION  13650000
           MOVE WS-CT-054              TO RG-CA10-I-AGENCIA-OPERACION   13650100
           MOVE WS-CT-1                TO RG-CA10-I-VERSION-HEADER      13650200
           MOVE RG-CA10-I-INPUT-CANAL-HEADER                            13650300
                                           TO RG-CA04-I-HDR-STD-IN      13650400
           MOVE '000'                      TO VP-COM-CODTAR(01:03)      13650500
           MOVE TI-TR02-COD-TARJETA-CRED(2:19) TO VP-COM-CODTAR         13650600
           MOVE 'SL'                       TO VP-COM-TRANSAC            13650700
                                                                        13650800
           PERFORM 5200-ASIGNAR-TERM-USER                               13650900
           MOVE RG-CA04-I-HDR-STD-IN   TO RG-CA10-I-INPUT-CANAL-HEADER  13651000
                                          VP-I-O-HEADER-ESTANDAR        13651100
      *                                                                 13651200
           EXEC CICS LINK PROGRAM  (TI-CW03-SRV-VP28)                   13651300
                          COMMAREA (VP-AREA-DATOS-N)                    13651400
                          LENGTH   (LENGTH OF VP-AREA-DATOS-N)          13651500
                          NOHANDLE                                      13651600
                          RESP(WS-RESP)                                 13651700
           END-EXEC.                                                    13651800
      *                                                                 13651900
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         13652000
      *       OBTENER MENSAJE PARA CCE                                  13652100
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       13652200
                                                                        13652300
              SET  TI-CA15-I-RC-APP-CCE   TO TRUE                       13652400
              SET  TI-CF06-88-RECH        TO TRUE                       13652500
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  13652600
                                             WS-TEMP-XX                 13652700
                                             WS-CODMSG-ESTRUCTURA(1: 2) 13652800
                                             TI-TR02-RESPONSE-CODE-CCE          
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  13652900
                                             WS-CODMSG-ESTRUCTURA(3: 4) 13653000
              MOVE WS-CT-1021             TO WS-CT-NUMER                13653100
                                             TI-TR02-COD-RESP-AMPLIADO          
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   13653200
                                             TI-TR02-ORIGEN-RESPUESTA           
              PERFORM 6100-OBTENER-MENSAJE                              13653300
                                                                        13653400
              MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA  13653500
              PERFORM 5600-ACTUALIZA-COMAREA                            13653600
                                                                        13653700
      *       OBTENER MENSAJE INTERNO                                   13653800
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       13653900
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       13654000
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     13654100
                                             WS-CODMSG-ESTRUCTURA       13654200
                                             WS-COD-ERROR-07            13654300
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             13654400
                                             WS-PROGRAM                 13654500
              MOVE 'LINK'                 TO WS-VARMSG-FUN              13654600
              MOVE TI-CW03-SRV-VP28       TO WS-VARMSG-RSO              13654700
                                                                        13654800
              PERFORM 6100-OBTENER-MENSAJE                              13654900
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             13655000
                                             WS-MENSAJE-TXT-EVE         13655100
                                                                        13655200
              PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      13655300
              PERFORM 5700-GRABAR-LOG-EVENTOS                           13655400
              PERFORM 6000-FINAL                                        13655500
           END-IF                                                       13655600
           .                                                            13655700
      ************************ FIN DE 3450-VALIDA-TARJETA               13655800
      **************************                                        13655900
       3900-REORDENAR-DOCUMENTO.                                        13656000
      **************************                                        13657000
      ******************************************************************13658000
      * REORDENAR LA CADENA PARA COMPLETARLA CON CEROS A LA IZQUIERDA  *13659000
      ******************************************************************13660000
                                                                        13670000
           MOVE SPACES             TO WS-DOC-ORD-TMP2                   13680000
           MOVE ZEROS              TO WS-X                              13690000
                                      WS-POS                            13700000
                                      WS-POS-INI                        13710000
                                      WS-LENGHT-CAD                     13720000
                                                                        13730000
           PERFORM VARYING WS-X FROM 1 BY 1                             13740000
                   UNTIL WS-X = WS-CTN-12                               13750000
                         OR WS-POS NOT EQUAL 0                          13760000
               IF  WS-DOC-ORD-TMP(WS-X: 1) = SPACES                     13770000
                                             OR HIGH-VALUES             13780000
                                             OR LOW-VALUES              13790000
                   MOVE WS-X           TO WS-POS                        13800000
               ELSE                                                     13810000
                   CONTINUE                                             13820000
               END-IF                                                   13830000
           END-PERFORM                                                  13840000
                                                                        13850000
           IF  WS-POS > 0                                               13860000
               COMPUTE WS-LENGHT-CAD = WS-POS - 1                       13870000
               COMPUTE WS-POS-INI = WS-CTN-12 - WS-LENGHT-CAD           13880000
               COMPUTE WS-POS-INI = WS-POS-INI + 1                      13890000
                                                                        13900000
               MOVE WS-DOC-ORD-CONST   TO WS-DOC-ORD-TMP2               13910000
               MOVE WS-DOC-ORD-TMP(1: WS-LENGHT-CAD)                    13920000
                                       TO                               13930000
                              WS-DOC-ORD-TMP2(WS-POS-INI: WS-LENGHT-CAD)13940000
                                                                        13950000
           END-IF                                                       13960000
           .                                                            13970000
      ************************ FIN DE 3900-REORDENAR-DOCUMENTO          13980000
      ********************                                              14121000
       4190-RUT-LINK-GRAL.                                              14122000
      ********************                                              14123000
                                                                        14124000
           EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                      14125000
                 COMMAREA (WS-CCAA)                                     14126000
                 LENGTH (WS-LGTH-CCAA)                                  14127000
                 RESP (WS-RESP)                                         14128000
                 RESP2 (WS-RESP2)                                       14129000
           END-EXEC.                                                    14129100
      *                                                                 14129200
           IF  WS-RESP  NOT EQUAL DFHRESP(NORMAL)                       14129300
      *        OBTENER MENSAJE PARA CCE                                 14129400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14129500
                                                                        14129600
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14129700
               SET  TI-CF06-88-RECH        TO TRUE                      14129800
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14129900
                                              WS-TEMP-XX                14130000
                                              WS-CODMSG-ESTRUCTURA(1: 2)14130100
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14130200
                                              WS-CODMSG-ESTRUCTURA(3: 4)14130300
               MOVE WS-CT-1021             TO WS-CT-NUMER               14130400
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14130500
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             14130600
                                                                        14130700
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14130800
               PERFORM 5600-ACTUALIZA-COMAREA                           14130900
                                                                        14131000
      *        OBTENER MENSAJE INTERNO                                  14131100
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14131200
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      14131300
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    14131400
                                              WS-CODMSG-ESTRUCTURA      14131500
                                              WS-COD-ERROR-07           14131600
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            14131700
                                              WS-PROGRAM                14131800
               MOVE 'LINK'                 TO WS-VARMSG-FUN             14131900
               MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             14132000
                                                                        14132100
               PERFORM 6100-OBTENER-MENSAJE                             14132200
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            14132300
                                              WS-MENSAJE-TXT-EVE        14132400
                                                                        14132500
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14132600
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14132700
               PERFORM 6000-FINAL                                       14132800
           END-IF                                                       14132900
           .                                                            14133000
      ************************ FIN DE 4190-RUT-LINK-GRAL                14133100
      *************************                                         14134000
       4100-EXTRAE-VALOR-PARAM.                                         14140000
      *************************                                         14150000
                                                                        14160000
           EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              14310000
                             INTO(TI-CF01-REG-PARAMETROS)               14311000
                           LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)     14312000
                           RIDFLD(TI-CF01-KEY03)                        14313000
                        KEYLENGTH(LENGTH OF TI-CF01-KEY03)              14313100
                             RESP(WS-RESP)                              14313200
           END-EXEC                                                     14313300
                                                                        14313400
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        14313500
               MOVE WS-RESP                TO WS-RESP-TXT               14313600
      *        OBTENER MENSAJE PARA CCE                                 14313700
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14313800
                                                                        14313900
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14314000
               SET  TI-CF06-88-RECH        TO TRUE                      14314100
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14314200
                                              WS-TEMP-XX                14314300
                                              WS-CODMSG-ESTRUCTURA(1: 2)14314400
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14314500
                                              WS-CODMSG-ESTRUCTURA(3: 4)14314600
               MOVE WS-CT-1021             TO WS-CT-NUMER               14314700
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14314800
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             14314900
                                                                        14315000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14315100
               PERFORM 5600-ACTUALIZA-COMAREA                           14315200
                                                                        14315300
      *        OBTENER MENSAJE INTERNO                                  14315400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14315500
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      14315600
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    14315700
                                              WS-CODMSG-ESTRUCTURA      14315800
                                              WS-COD-ERROR-07           14315900
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            14316000
                                              WS-PROGRAM                14316100
               MOVE TI-CW03-FILE-PARAMETROS                             14316200
                                           TO WS-VARMSG-RSO             14316300
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             14316400
                                                                        14316500
               PERFORM 6100-OBTENER-MENSAJE                             14316600
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            14316700
                                              WS-MENSAJE-TXT-EVE        14316800
                                                                        14316900
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14317000
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14317100
               PERFORM 6000-FINAL                                       14317200
           ELSE                                                         14317300
               CONTINUE                                                 14317400
           END-IF                                                       14317500
           .                                                            14317600
      ************************ FIN DE 4100-EXTRAE-VALOR-PARAM           14317700
      *******************                                               14318000
       4155-HOMOLOGA-DOC.                                               14320000
      *******************                                               14330000
           MOVE SPACES                     TO TI-CF01-KEY03             14340000
           MOVE WS-CT-03                   TO TI-CF01-KEY03-TIP-PRM     14350000
           MOVE WS-CT-08C                  TO TI-CF01-KEY03-CTABL       14360000
           MOVE WS-TIPO-DOC-ORD-HOMOL      TO TI-CF01-KEY03-DTABL       14370000
      *                                                                 14380000
           EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              14390000
                INTO(TI-CF01-REG-PARAMETROS)                            14400000
                LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)                14410000
                RIDFLD(TI-CF01-KEY03)                                   14420000
                KEYLENGTH(LENGTH OF TI-CF01-KEY03)                      14430000
                RESP(WS-RESP)                                           14440000
           END-EXEC                                                     14450000
                                                                        14460000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        14470000
               MOVE WS-RESP                TO WS-RESP-TXT               14480000
      *        OBTENER MENSAJE PARA CCE                                 14490000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14500000
                                                                        14510000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14520000
               SET  TI-CF06-88-RECH        TO TRUE                      14530000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14540000
                                              WS-TEMP-XX                14550000
                                              WS-CODMSG-ESTRUCTURA(1: 2)14551000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14552000
                                              WS-CODMSG-ESTRUCTURA(3: 4)14553000
               MOVE WS-CT-1021             TO WS-CT-NUMER               14554000
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14555000
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             14556000
                                                                        14557000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14558000
               PERFORM 5600-ACTUALIZA-COMAREA                           14559000
                                                                        14559100
      *        OBTENER MENSAJE INTERNO                                  14559200
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14559300
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      14559400
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    14559500
                                              WS-CODMSG-ESTRUCTURA      14559600
                                              WS-COD-ERROR-07           14559700
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            14559800
                                              WS-PROGRAM                14559900
               MOVE TI-CW03-FILE-PARAMETROS                             14560000
                                           TO WS-VARMSG-RSO             14560100
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             14560200
                                                                        14560300
               PERFORM 6100-OBTENER-MENSAJE                             14560400
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            14560500
                                              WS-MENSAJE-TXT-EVE        14560600
                                                                        14560700
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14560800
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14560900
               PERFORM 6000-FINAL                                       14561000
           ELSE                                                         14561100
               MOVE TI-CF01-DTBL-VALOR(1:1)    TO WS-TIPO-DOC-ORD-HOMOL 14561200
           END-IF                                                       14561300
           .                                                            14561400
      ************************ FIN DE 4155-HOMOLOGA-DOC                 14561500
      *********************                                             14561600
       5000-CARGA-CABECERA.                                             14562000
      *********************                                             14563000
                                                                        14580000
           INITIALIZE OQ-TR27-I-TRAMA                                   14581000
           REPLACING  ALPHANUMERIC DATA BY SPACES                       14582000
                      NUMERIC DATA BY ZEROS                             14583000
                                                                        14584000
      * CARGAMOS DATOS AL ORQUESTADOR.                                  14590000
           MOVE 'OQ10'                 TO RG-CA10-I-COD-INTERFAZ        14600000
           MOVE '1'                    TO RG-CA10-I-COD-INSTITUCION     14610000
           MOVE SPACES                 TO RG-CA10-I-CANAL-USUARIO       14620000
           MOVE 'APTI'                 TO RG-CA10-I-CANAL-USUARIO(1:4)  14630000
           MOVE RG-CA05-O-0A-AMBIENTE  TO RG-CA10-I-CANAL-USUARIO(5:3)  14640000
      * CODIGO DE MATRICULA                                             14650000
           MOVE SPACES                 TO RG-CA10-I-K-USR-CODIGO        14660000
           MOVE WS-CT-S                TO RG-CA10-I-FLAG-GREM-94        14670000
           MOVE WS-CT-S                TO RG-CA10-I-FLAG-CTA-ESP        14680000
           MOVE SPACES                 TO RG-CA10-I-NRO-OPE-CANAL       14690000
           MOVE ZEROS                  TO WS-NRO-OPERACION              14691000
           MOVE TI-TR02-AUTORIZAT-ID-RESP                               14692000
                                       TO WS-NRO-OPERACION(3:6)         14692100
           MOVE WS-NRO-OPERACION       TO RG-CA10-I-NRO-OPE-CANAL       14693000
           MOVE WS-CT-01               TO RG-CA10-I-VERSION             14720000
           MOVE WS-CT-0                TO RG-CA10-I-FLAG-EXT-OPE        14730000
           MOVE ZEROS                  TO RG-CA10-I-NRO-OPE-CANAL-A-EXT 14740000
           MOVE SPACES                 TO RG-CA10-I-TERMINAL-CANAL      14750000
           MOVE SPACES                 TO RG-CA10-I-TERMINAL-CANAL      14760000
           MOVE SPACES                 TO RG-CA10-I-TERM-CICS-TETI      14770000
           MOVE 'BUKCTA01'             TO RG-CA10-I-KEY-MACRO-OPE       14780000
           MOVE SPACES                 TO RG-CA10-I-K-USR-CODIGO-SUP    14790000
           MOVE 0                      TO RG-CA10-I-FLAG-AUTORIZACION   14800000
           MOVE 0                      TO RG-CA10-I-FLAG-MODO-ENTRADA   14810000
           MOVE '0'                    TO RG-CA10-I-FLAG-NEXT-DAY       14820000
           MOVE WS-HORA-INI            TO RG-CA10-I-HORA-CANAL          14830000
           MOVE WS-FECHA-INI           TO RG-CA10-I-FECHA-CANAL         14840000
           MOVE 0                      TO RG-CA10-I-FLAG-STR-FWRD       14850000
           MOVE TI-CW03-SUCAGE-SUC(1)  TO RG-CA10-I-SUCURSAL-OPERACION  14860000
           MOVE TI-CW03-SUCAGE-AGE(1)  TO RG-CA10-I-AGENCIA-OPERACION   14870000
           MOVE SPACES                 TO RG-CA10-I-FLAG-CONSUMO-SRV    14880000
           MOVE WS-CT-2                TO RG-CA10-I-VERSION-HEADER      14890000
                                                                        14891000
           PERFORM 5200-ASIGNAR-TERM-USER                               14892000
           MOVE RG-CA04-I-HDR-STD-IN   TO RG-CA10-I-INPUT-CANAL-HEADER  14893000
                                                                        14894000
           MOVE RG-CA10-I-INPUT-CANAL-HEADER TO OQ-TR27-I-HDR           14900000
           .                                                            14900100
      ************************ FIN DE 5000-CARGA-CABECERA               14901000
      *********************                                             14910000
       5100-CARGA-DETALLES.                                             14920000
      *********************                                             14921000
           MOVE 'ORQUESTADOR'     TO OQ-TR27-I-ID-ORQUESTADOR           14940000
           MOVE TI-CF06-COD-MON   TO OQ-TR27-I-MON-OPE                  14950000
           MOVE TI-CF06-IMPORTE   TO OQ-TR27-I-IMP-OPE                  14960000
           MOVE 'BUCKET CARGO'    TO OQ-TR27-I-ID-BUCKET-CARGO          14970000
           MOVE WS-CT-063         TO OQ-TR27-I-B-BUCKET-CARGO           14980000
                                                                        14990000
           IF TI-TR02-INDI-MISMO-CLIENTE = WS-CT-M                      15000000
              MOVE WS-CT-1N       TO OQ-TR27-I-C-IND-CTAS-PROPIAS       15010000
           ELSE                                                         15020000
              MOVE WS-CT-0        TO OQ-TR27-I-C-IND-CTAS-PROPIAS       15030000
           END-IF                                                       15040000
                                                                        15050000
           MOVE 'MEDIO DE CARGO'  TO OQ-TR27-I-ID-MEDIOS-CARGO          15060000
           MOVE 'C'               TO OQ-TR27-I-C-TIP-MEDIO              15070000
           MOVE 'BCKT'            TO OQ-TR27-I-C-COD-CARGO              15080000
           MOVE TI-CF06-COD-MON   TO OQ-TR27-I-C-MON-MEDIO              15090000
           MOVE ZEROS             TO OQ-TR27-I-C-NRO-GLOSA              15100000
           MOVE '000000'          TO OQ-TR27-I-C-COD-UTC                15110000
           MOVE '0000'            TO OQ-TR27-I-C-FEC-EXP-TC             15120000
           MOVE '000000000'       TO OQ-TR27-I-C-COD-ESTAB-TC           15130000
           MOVE '00'              TO OQ-TR27-I-C-NRO-CUOTAS-TC          15140000
           MOVE WSV-MONTO20       TO WS-IMPORTE-20                      15150000
           MOVE WS-SIGNO          TO OQ-TR27-I-C-IMP-COM-TC(1:1)        15160000
           MOVE WS-SOLES          TO OQ-TR27-I-C-IMP-COM-TC(2:14)       15170000
           MOVE WS-PUNTO          TO OQ-TR27-I-C-IMP-COM-TC(16:1)       15180000
           MOVE WS-CENTI          TO OQ-TR27-I-C-IMP-COM-TC(17:4)       15190000
           MOVE WSV-MONTO20       TO WS-IMPORTE-20                      15200000
           MOVE WS-SIGNO          TO OQ-TR27-I-C-IMP-COM1-TC(1:1)       15210000
           MOVE WS-SOLES          TO OQ-TR27-I-C-IMP-COM1-TC(2:14)      15220000
           MOVE WS-PUNTO          TO OQ-TR27-I-C-IMP-COM1-TC(16:1)      15230000
           MOVE WS-CENTI          TO OQ-TR27-I-C-IMP-COM1-TC(17:4)      15240000
                                                                        15250000
           MOVE 'COMPRA VENTA ME' TO OQ-TR27-I-ID-CVME                  15260000
           MOVE 'NOR'             TO OQ-TR27-I-X-CLASE-TIPO-CAMB        15270000
                                                                        15280000
           MOVE WSV-MONTO20       TO WSV-MONTOS                         15290000
           MOVE WSV-MONTOS(2:14)  TO WSV-MONTO-A(1:14)                  15300000
           MOVE WSV-MONTOS(17:4)  TO WSV-MONTO-A(15:4)                  15310000
           MOVE WSV-MONTO-N       TO OQ-TR27-I-X-IMP-CONTRAVALOR        15320000
                                                                        15330000
           MOVE WSV-MONT12(1:1)   TO OQ-TR27-I-X-IMP-VAL-TIPO-CAMB(1:1) 15340000
           MOVE WSV-MONT12(2:4)   TO OQ-TR27-I-X-IMP-VAL-TIPO-CAMB(2:4) 15350000
           MOVE WSV-MONT12(6:1)   TO OQ-TR27-I-X-IMP-VAL-TIPO-CAMB(6:1) 15360000
           MOVE WSV-MONT12(7:6)   TO OQ-TR27-I-X-IMP-VAL-TIPO-CAMB(7:6) 15370000
                                                                        15380000
           MOVE '00000000'        TO OQ-TR27-I-X-NRO-CONSULTA-TCAMB     15390000
           MOVE 'BUCKET ABONO'    TO OQ-TR27-I-ID-BUCKET-ABONO          15400000
           MOVE 'MEDIO DE ABONO'  TO OQ-TR27-I-ID-MEDIOS-ABONO          15410000
                                                                        15420000
           MOVE OPB-COD-CFAM(1)   TO OQ-TR27-I-A-COD-FAM                15430000
           MOVE OPB-COD-PROD(1)   TO OQ-TR27-I-A-COD-PRO                15440000
           MOVE SPACES            TO OQ-TR27-I-A-COD-SPR                15450000
                                                                        15460000
           MOVE 'A'               TO OQ-TR27-I-A-TIP-MEDIO              15470000
           MOVE 'CTAD'            TO OQ-TR27-I-A-COD-ABONO              15480000
           MOVE TI-CF06-COD-MON   TO OQ-TR27-I-A-MON-MEDIO              15490000
           MOVE SPACES            TO OQ-TR27-I-A-FEC-VALOR              15500000
      * EXTRAE NOMBRE CORTO DE BANCO                                    15510000
      *                                                                 15520000
           MOVE '00000'           TO OQ-TR27-I-A-NRO-GLOSA              15530000
           MOVE SPACES            TO OQ-TR27-I-A-APL-GLOSAS             15540000
           MOVE SPACES            TO OQ-TR27-I-A-GLOSA2                 15550000
           MOVE SPACES            TO OQ-TR27-I-A-MARK-ENCAJE            15560000
           MOVE '0000'            TO OQ-TR27-I-A-FEXP-TC                15570000
           MOVE '000000000'       TO OQ-TR27-I-A-COD-ESTAB-TC           15580000
           MOVE SPACES            TO OQ-TR27-I-A-FLG-PAG-3ROS-TC        15590000
           MOVE SPACES            TO OQ-TR27-I-A-NRO-PLAN-TC            15600000
           MOVE SPACES            TO OQ-TR27-I-A-SEC-PLAN-TC            15610000
           MOVE ZEROS             TO WS-SOLES WS-CENTI                  15620000
           MOVE SPACES            TO WS-SIGNO                           15630000
           MOVE TI-TR02-IMPORTE(1:10)TO WS-SOLES(5:10)                  15640000
           MOVE '.'               TO WS-PUNTO                           15650000
           MOVE TI-TR02-IMPORTE(11:2) TO WS-CENTI(1:2)                  15660000
           MOVE WS-IMPORTE-20         TO OQ-TR27-I-IMP-OPE              15670000
           .                                                            15670100
      ************************ FIN DE 5100-CARGA-DETALLES               15671000
      ************************                                          15672000
       5200-ASIGNAR-TERM-USER.                                          15673000
      ************************                                          15674000
      *                                                                 15675000
           INITIALIZE  RG-CA04-TETI-USER                                15676000
           REPLACING  ALPHANUMERIC DATA BY SPACES                       15677000
                      NUMERIC DATA BY ZEROS                             15678000
                                                                        15679000
           SET  RG-CA04-88-COMMAREA          TO TRUE                    15680000
           SET  RG-CA04-I-88-ASIGNA          TO TRUE                    15680100
           MOVE RG-CA10-I-INPUT-CANAL-HEADER TO RG-CA04-I-HDR-STD-IN    15680200
                                                                        15680300
                                                                        15680400
           MOVE WS-RTN-ASIGNA-TETI           TO WS-RTN-SGTE             15680500
           MOVE RG-CA04-TETI-USER            TO WS-CCAA                 15680600
           MOVE LENGTH OF RG-CA04-TETI-USER  TO WS-LGTH-CCAA            15680700
           PERFORM  4190-RUT-LINK-GRAL                                  15680800
           MOVE WS-CCAA                      TO RG-CA04-TETI-USER       15680900
                                                                        15681000
           IF  RG-CA04-O-RC-NUM NOT EQUAL WS-CT-0000                    15681100
      *        OBTENER MENSAJE PARA CCE                                 15681200
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      15681300
                                                                        15681400
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      15681500
               SET  TI-CF06-88-RECH        TO TRUE                      15681600
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     15681700
                                          WS-TEMP-XX                    15681800
                                          WS-CODMSG-ESTRUCTURA(1: 2)    15681900
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     15682000
                                          WS-CODMSG-ESTRUCTURA(3: 4)    15682100
               MOVE WS-CT-1021         TO WS-CT-NUMER                   15682200
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      15682300
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             15682400
                                                                        15682500
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     15682600
                                                                        15682700
      *        OBTENER MENSAJE INTERNO                                  15682800
               MOVE RG-CA04-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT        15682900
                                          WS-COD-ERROR-07               15683000
               MOVE WS-RTN-ASIGNA-TETI TO TI-CF06-PRGNOM                15683100
                                          WS-PROGRAM                    15683200
               MOVE RG-CA04-O-MSG      TO TI-CF06-TXTMSG                15683300
                                          WS-MENSAJE-TXT-EVE            15683400
                                                                        15683500
               PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     15683600
               PERFORM 5600-ACTUALIZA-COMAREA                           15683700
               PERFORM 5700-GRABAR-LOG-EVENTOS                          15683800
               PERFORM 6000-FINAL                                       15683900
           END-IF                                                       15684000
           .                                                            15684100
      ************************ FIN DE 5200-ASIGNAR-TERM-USER            15684200
      ******************************                                    15684300
       5500-ACTUALIZA-MASTER-TRANSF.                                    15684400
      ******************************                                    15684500
      ******************************************************************15684600
      * GRABAR EN MAESTRO DE TRANSFERENCIAS                            *15684700
      ******************************************************************15684800
                                                                        15684900
      *GNS-I                                                            06570000
           MOVE TI-CF06-ID-TRANS-CCE-ONLINE TO TI-CF06-INSTRUCTION-ID   06540000
      *GNS-F                                                            06570000
      *    EXEC CICS REWRITE DATASET (TI-CW03-FILE-MAESTRO)             00160022
           EXEC CICS REWRITE    FILE (WS-FILE-NM-MAESTRO)               00160022
                                FROM (TI-CF06-REG-TRANS)                15685100
                              LENGTH (LENGTH OF TI-CF06-REG-TRANS)      15685200
                                RESP (WS-RESP)                          15685300
           END-EXEC                                                     15685400
                                                                        15685500
           EVALUATE WS-RESP                                             15685600
             WHEN DFHRESP(NORMAL)                                       15685700
               CONTINUE                                                 15685800
             WHEN OTHER                                                 15685900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      15687000
                                                                        15687100
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      15687200
               SET  TI-CF06-88-RECH        TO TRUE                      15687300
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 15687400
                                              WS-TEMP-XX                15687500
                                              WS-CODMSG-ESTRUCTURA(1: 2)15687600
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 15687700
                                              WS-CODMSG-ESTRUCTURA(3: 4)15687800
               MOVE WS-CT-1021             TO WS-CT-NUMER               15687900
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  15688000
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             15688100
                                                                        15688200
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 15688300
               PERFORM 5600-ACTUALIZA-COMAREA                           15688400
                                                                        15688500
      *        OBTENER MENSAJE INTERNO                                  15688600
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      15688700
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      15688800
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    15688900
                                              WS-CODMSG-ESTRUCTURA      15689000
                                              WS-COD-ERROR-07           15689100
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            15689200
                                              WS-PROGRAM                15689300
      *        MOVE TI-CW03-FILE-MAESTRO                                00160022
               MOVE WS-FILE-NM-MAESTRO     TO WS-VARMSG-RSO             00160022
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             15689600
                                                                        15689700
               PERFORM 6100-OBTENER-MENSAJE                             15689800
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            15689900
                                              WS-MENSAJE-TXT-EVE        15690000
                                                                        15690100
               PERFORM 5700-GRABAR-LOG-EVENTOS                          15690200
               PERFORM 6000-FINAL                                       15690300
           END-EVALUATE                                                 15690400
           .                                                            15690500
      ************************ FIN DE 5500-ACTUALIZA-MASTER-TRANSF      15690600
      ************************                                          15690700
       5600-ACTUALIZA-COMAREA.                                          15690800
      ************************                                          15690900
      ******************************************************************15691000
      *ACTUALIZA COMMAREA CON CAMPO ERRADO                              15691100
      ******************************************************************15691200
           MOVE WS-TEMP-XX             TO TI-TR02-RESPONSE-CODE-CCE     15691300
           MOVE WS-CT-NUMER            TO TI-TR02-COD-RESP-AMPLIADO     15691400
           MOVE WS-CT-001              TO TI-TR02-ORIGEN-RESPUESTA      15691500
           MOVE WS-MENSAJE-TXT         TO TI-TR02-MENSAJE-RESPUESTA     15691600
      *    MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     00160022
           MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
           MOVE TI-CA02-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
           .                                                            15691800
      ************************ FIN DE 5600-ACTUALIZA-COMAREA            15691900
      *************************                                         15692000
       5700-GRABAR-LOG-EVENTOS.                                         15692100
      *************************                                         15692200
      ******************************************************************15692300
      * GRABAR MOTIVO DE ERROR EN EL LOG DE EVENTO                      15692400
      ******************************************************************15692500
           INITIALIZE  TI-CF07-REG-TRANS                                15692600
                       REPLACING  ALPHANUMERIC DATA BY SPACES           15692700
                                  NUMERIC DATA BY ZEROS                 15692800
      *                                                                 15692900
           SET  TI-CF07-88-COD-PROCESO-TRN TO TRUE                      15693000
           SET  TI-CF07-88-TIPO-ROL-RECEPT TO TRUE                      15693100
           MOVE TI-CF06-ESTADO             TO TI-CF07-ESTADO            15693200
           MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 15693300
           MOVE TI-TR02-CANAL              TO TI-CF07-CANAL-CCE         15693400
           MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF07-BIN-ADQUIRIENTE   15693500
           MOVE TI-TR02-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       15693600
           MOVE TI-TR02-DATE-LOCAL         TO TI-CF07-FECHA-TRANS       15693700
           MOVE TI-TR02-TIME-LOCAL         TO TI-CF07-HORA-TRANS        15693800
           MOVE WS-COD-ERROR-07            TO TI-CF07-COD-ERROR         15693900
           MOVE WS-MENSAJE-TXT-EVE         TO TI-CF07-MSG-ERROR         15694000
           MOVE WS-PROGRAM                 TO TI-CF07-PROG              15694100
           MOVE TI-CF06-REG-TRANS          TO TI-CF07-REG-CF06-TRANS    15694200
      *                                                                 15694300
      *    EXEC  CICS  WRITE  FILE (TI-CW03-FILE-EVEN-LOG)              00160022
           EXEC  CICS  WRITE  FILE (WS-FILE-NM-EVEN-LOG)                00160022
                              FROM (TI-CF07-REG-TRANS)                  15694500
                            LENGTH (LENGTH OF TI-CF07-REG-TRANS)        15694600
                            RIDFLD (WS-RBA-ESDS)                        15694700
                               RBA                                      15694800
                              RESP (WS-RESP)                            15694900
           END-EXEC                                                     15695000
      *                                                                 15695100
           EVALUATE WS-RESP                                             15695200
               WHEN DFHRESP(NORMAL)                                     15695300
                    CONTINUE                                            15695400
               WHEN OTHER                                               15695500
                    PERFORM 6000-FINAL                                  15695600
           END-EVALUATE                                                 15695700
           .                                                            15695800
      ************************ FIN DE 5700-GRABAR-LOG-EVENTOS           15695900
      ************                                                      15696000
       6000-FINAL.                                                      15696100
      ************                                                      15697000
      ******************************************************************15700000
      * FIN DEL PROCESO Y ENVIA MENSAJE AL OPERADOR                    *15710000
      ******************************************************************15711000
                                                                        15730000
      *    MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     00160022
           MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
           MOVE TI-CA02-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
                                                                        15732000
           EXEC CICS                                                    15740000
              RETURN                                                    15750000
           END-EXEC                                                     15760000
           .                                                            15760100
      ************************ FIN DE 6000-FINAL                        15760200
      **********************                                            15761000
       6100-OBTENER-MENSAJE.                                            15762000
      **********************                                            15763000
      ******************************************************************15764000
      * MUEVE DATOS PARA LA RUTINA DE ARMADO DE MENSAJES               *15765000
      ******************************************************************15766000
                                                                        15767000
           MOVE WS-CODMSG-ESTRUCTURA       TO TI-CA15-I-RC-COD          15768000
           MOVE WS-PROGRAM-ID              TO TI-CA15-I-VAR-PROGRAMA    15769000
           MOVE WS-VARMSG-FUN              TO TI-CA15-I-VAR-FUNCION     15769100
           MOVE WS-VARMSG-RSO              TO TI-CA15-I-VAR-RECURSO     15769200
           MOVE WS-VARMSG-ARG              TO TI-CA15-I-VAR-ARGUMENTO   15769300
           MOVE WS-VARMSG-TXT              TO TI-CA15-I-VAR-TEXTO       15769400
           MOVE WS-RESP                    TO TI-CA15-I-EIBRESP         15769500
           MOVE WS-RESP2                   TO TI-CA15-I-EIBRESP2        15769600
           MOVE TI-CW03-PGM-MENSAJES       TO WS-RTN-SGTE               15769700
           MOVE TI-CA15-I-O-MENSAJES       TO WS-CCAA                   15769800
           MOVE LENGTH OF TI-CA15-I-O-MENSAJES TO WS-LGTH-CCAA          15769900
                                                                        15770000
      *    NO SE UTILIZA EL LLAMADO AL LINK-GRAL PARA NO CAER EN BUCLE  15770100
      *    SI EL PROGRAMA NO ESTA DISPONIBLE                            15770200
           EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                      15770300
                            COMMAREA (WS-CCAA)                          15770400
                              LENGTH (WS-LGTH-CCAA)                     15770500
                                RESP (WS-RESP)                          15770600
                               RESP2 (WS-RESP2)                         15770700
           END-EXEC                                                     15770800
                                                                        15770900
           IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                      15771000
               STRING 'BCTITPR3' 'RUTINA' WS-RTN-SGTE                   15771100
                      'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO 15771200
                      WS-TXTMSG                                         15771300
                                                                        15771400
           ELSE                                                         15771500
               MOVE WS-CCAA                    TO TI-CA15-I-O-MENSAJES  15771600
               MOVE TI-CA15-O-RCODE            TO WS-CODMSG-ESTRUCTURA  15771700
               MOVE TI-CA15-O-RC-MSG           TO WS-TXTMSG             15771800
                                                    WS-MENSAJE-TXT      15771900
           END-IF                                                       15772000
           .                                                            15772100
      ************************ FIN DE 6100-OBTENER-MENSAJE              15772200
      **************************                                        15773000
       3700-FORMATEAR-DOCUMENTO.                                        15780000
      **************************                                        15781000
      ******************************************************************15782000
      * INVOCAR RUTINA SGCPPDGC - VERIFICAR COPY                       *15800000
      ******************************************************************15801000
                                                                        15820000
           PERFORM 3750-VALIDA-CARACTERES                               15830000
           .                                                            15831000
      ************************ FIN DE 3700-FORMATEAR-DOCUMENTO          15840000
      ************************                                          15850000
       3750-VALIDA-CARACTERES.                                          15860000
      ************************                                          15861000
                                                                        15862000
           MOVE DGC-NUM-ICLI (IND)  TO  WS-NROCLI-CONSIS-WORK           15880000
           MOVE SPACES              TO  WS-NROCLI-CONSIS-WORK1          15890000
           MOVE 0                   TO  WS-J WS-K                       15900000
           PERFORM 8 TIMES                                              15910000
             ADD  1   TO WS-J                                           15920000
             MOVE WS-NROCLI-CONSIS-WORK (WS-J:1) TO WS-VALIDO           15930000
             IF WS-VALIDO-NUM OR WS-VALIDO-ALF                          15940000
                ADD 1 TO WS-K                                           15950000
                MOVE WS-NROCLI-CONSIS-WORK (WS-J:1) TO                  15960000
                     WS-NROCLI-CONSIS-WORK1 (WS-K:1)                    15970000
             ELSE                                                       15980000
                CONTINUE                                                15990000
             END-IF                                                     16000000
           END-PERFORM.                                                 16010000
           MOVE WS-NROCLI-CONSIS-WORK1 TO DGC-NUM-ICLI (IND)            16020000
           .                                                            16020100
      ************************ FIN DE 3750-VALIDA-CARACTERES            16021000
      ***************                                                   16400000
       9000-TERMINAR.                                                   16410000
      ***************                                                   16420000
                                                                        16430000
           SET TI-CF06-88-ACEP             TO TRUE                      16481000
           MOVE WS-CT-00                   TO TI-CF06-RESPONSE-CODE-CCE 16482000
           MOVE WS-CT-0000                 TO TI-CF06-COD-RESP-AMPLIADO 16483000
           MOVE WS-CT-001                  TO TI-CF06-ORIGEN-RESPUESTA  16484000
           MOVE WS-CT-TRANSOK              TO TI-CF06-MENSAJE-RESPUESTA 16485000
           MOVE WS-IDC                     TO TI-CF06-IDC-BEN           16490000
           IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201                        16491000
               SET  TI-CF06-88-SI-REENV     TO TRUE                     16491100
               MOVE TI-TR02-TIPO-PROCESO    TO TI-CF06-TIPO-PROCESO     16491200
                                                                        16492000
           END-IF                                                       16493000
                                                                        16500000
           PERFORM 5500-ACTUALIZA-MASTER-TRANSF                         16510000
                                                                        16520000
           MOVE WS-CT-00                   TO TI-TR02-RESPONSE-CODE-CCE 16561000
           MOVE WS-CT-0000                 TO TI-TR02-COD-RESP-AMPLIADO 16562000
           MOVE WS-CT-001                  TO TI-TR02-ORIGEN-RESPUESTA  16563000
           MOVE WS-CT-TRANSOK              TO TI-TR02-MENSAJE-RESPUESTA 16564000
           MOVE WS-CT-TRANSOK              TO WS-MENSAJE-TXT            16565000
           MOVE WS-CT-0000                 TO WS-CT-NUMER               16566000
                                                                        16570000
           PERFORM 6000-FINAL                                           16580000
           .                                                            16581000
      ************************ FIN DE 9000-TERMINAR                     16590000
      ********************                                              16591000
       9998-OBTIENE-ABEND.                                              16600000
      ********************                                              16601000
      ******************************************************************16602000
      *OBTIENE EL CODIGO DEL ABEND GENERADO POR EL MODULO              *16620000
      ******************************************************************16621000
                                                                        16640000
           EXEC  CICS                                                   16650000
                 ASSIGN ABCODE(WS-ABCODE)                               16660000
                     ABPROGRAM(WS-ABPROGRAM)                            16670000
           END-EXEC                                                     16680000
           .                                                            16680100
      ************************ FIN DE 9998-OBTIENE-ABEND                16681000
      *************************                                         16690000
       9999-MANEJO-EXCEPCIONES.                                         16700000
      *************************                                         16701000
      ******************************************************************16702000
      * ACTUALIZAR ESTADO DE LA APLICACION CAMB A ACTIVO EN BCXRAV03   *16720000
      ******************************************************************16721000
                                                                        16740000
           PERFORM  9998-OBTIENE-ABEND                                  16750000
                                                                        16760000
           SET  WS-SI-EXISTE-ERROR         TO TRUE                      16770000
           MOVE WS-CT-001                         TO WS-CODMSG          16780000
           MOVE WS-ABCODE                  TO WS-TXTMSG                 16790000
           PERFORM 6000-FINAL                                           16800000
           .                                                            16810000
      ************************ FIN DE 9999-MANEJO-EXCEPCIONES           16820000
