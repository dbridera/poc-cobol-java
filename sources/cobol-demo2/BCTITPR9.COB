       IDENTIFICATION DIVISION.                                         00010000
      *************************                                         00020000
       PROGRAM-ID.    BCTITPR9.                                         00030000
       AUTHOR.        TCS-GUNS.                                         00040000
       INSTALLATION.  BANCO DE CREDITO.                                 00050000
       DATE-WRITTEN.  2022-MARZO.                                       00060000
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
      * OBJETIVOS : RECEPTOR CONFIRMACION/CANCELACION 2                *00210000
      *                                                                *00220000
      *                                                                *00230000
      * FUNCIONES : 1. SE IMPLEMENTARA EL SERVICIO QUE SER¡ INVOCADO   *00240000
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
      *                                                                 00441001
      *----------------------------------------------------------------*00442001
      *              C O N T R O L   D E   C A M B I O S               *00443001
      *----------------------------------------------------------------*00444001
      * MODIFICACION  : VOCALINK (BASADO EN BCTITPR3)                  *00160022
      * FECHA         : 2022                                           *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : TA000184140                                    *00160022
      *----------------------------------------------------------------*00069579
      * MODIFICACION  : VOCALINK BYPASS A GLOSA DESDE EMISOR           *00160022
      * FECHA         : 10 MAYO 2022                                   *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : TA000188752                                    *00160022
      *----------------------------------------------------------------*00069579
      * MODIFICACION  : VOCALINK- NO BUSCAR USUSRIO-TETI EN RG + AJUSTE*00160022
      * FECHA         : 23 MAYO 2022                                   *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : TA000188957                                    *00160022
      *----------------------------------------------------------------*00069579
      ******************************************************************00071352
      * MODIFICACION  : Se incluye TETI IRZ9 y usuario IR0999 para Regu*00071352
      *               : larizacion de transferencias batch RECEPTOR    *00071352
      *               : Se Incluye TETI : IRZ7 y Usuario : IR0997      *00071352
      *               : Para Transferencia proceso en linea y reenv='01*00071352
      *               : Se Incluye TETI y usuario en espacios          *00071352
      *               : Para Confirmacion de abono en linea y reenv='00*00071352
      * FECHA         : 10/20/2022                                     *00071352
      * AFECTA A      : Transferencias interbancarias FLUJO RECEPTOR   *00071352
      * MODIFICADO POR: IVC-TCS                                        *00071352
      * NRO.TICKET    :TA000193512                                     *00071352
      ******************************************************************00069579
      *----------------------------------------------------------------*00069579
      * MODIFICACION  : ADICION ENVIO DE NUEVOS CAMPOS                 *        
      *                 TI-CAR2-GLOSA-BCP                              *        
      *                 TI-TRR2-GLOSA-BCP                              *        
      * FECHA         : 15-03-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00127821                                    *        
      ******************************************************************        
      * MODIFICACION  : COMPLETA VALORES FALTANTES DE DATOS            *        
      * FECHA         : 30-05-2023                                     *        
      * AFECTA A      : FLUJO RECEPTOR                                 *        
      * MODIFICADO POR: TCS - JCS                                      *        
      * NRO.TICKET    : MVP00139677                                    *        
      ******************************************************************        
      * MODIFICACION  : MODIFICACION DE GLOSA - FLUJO RECEPTOR         *00153789
      * FECHA         : 08/02/2024                                     *00153789
      * AFECTA A      : BCP                                            *00153789
      * MODIFICADO POR: TCS                                            *00153789
      * NRO.TICKET    : OCD00014591                                    *00153789
      *----------------------------------------------------------------*00153789
      *                                                                 00449301
       ENVIRONMENT DIVISION.                                            00450000
      **********************                                            00460000
       DATA DIVISION.                                                   00470000
      *************************                                         00480000
       WORKING-STORAGE SECTION.                                         00490000
      *************************                                         00500000
       01  WS-VARIABLES-GENERALES.                                      00510000
           05  WS-IRZ9                   PIC  X(04)  VALUE 'IRZ9'.      TA193512
           05  WS-IR0999                 PIC  X(06)  VALUE 'IR0999'.    TA193512
           05  WS-IRZ7                   PIC  X(04)  VALUE 'IRZ7'.      TA193512
           05  WS-IR0997                 PIC  X(06)  VALUE 'IR0997'.    TA193512
                                                                                
           05  WS-RBA-ESDS               PIC S9(08)  COMP.              00520000
      *GNS-I                                                                    
      *    05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR3'.  00530000
           05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR9'.  00530000
      *GNS-F                                                                    
           05  WS-PROGRAM                PIC  X(08)  VALUE SPACES.      00531000
      *GNS-I                                                                    
      *    05  WS-PROG-CONSULTA          PIC  X(08)  VALUE 'BCTITPR2'.  00540000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV03'.  00690000
           05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV04'.  00690000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    05  WS-TR02-MSGE-TYPE-ID      PIC  X(30)                     00740000
      *                                  VALUE 'TI-TR02-MSGE-TYPE-ID'.  00750000
      *    05  WS-TR02-COD-PROCESO       PIC  X(30)                     00760000
      *                                  VALUE 'TI-TR02-COD-PROCESO '.  00770000
           05  WS-CT-TIPO-TRANSF         PIC  X(20)                     00810000
                                         VALUE 'TIPO DE TRANSF.     '.  00820000
           05  WS-CT-MONEDA-CUENTA       PIC  X(20)                     00810000
                                         VALUE 'MONEDA EN CUENTA    '.  00820000
           05  WS-CT-TIPO-CUENTA         PIC  X(20)                     00810000
                                         VALUE 'TIPO DE CUENTA      '.  00820000
           05  WS-CT-ENTIDAD-ORIGEN      PIC  X(20)                     00810000
                                         VALUE 'ENTIDAD ORIGEN      '.  00820000
           05  WS-CT-ESTADO              PIC  X(20)                     00810000
                                         VALUE 'ESTADO DE TRANSF.   '.  00820000
           05  WS-CT-COD-PROCESO-CNF-CAN PIC  X(20)                     00810000
                                         VALUE 'COD PROCESO CNF CAN '.  00820000
      *GNS-F                                                                    
           05  WS-I-TRAMA                PIC X(1600).                   00780000
           05  WS-CT-10C                 PIC X(03)    VALUE '010'.      00790000
           05  WS-CT-05C                 PIC X(03)    VALUE '005'.      00800000
JCS   *MVP00139677--*                                                           
           05  WS-CT-DS24                PIC X(04)    VALUE 'DS24'.     00800000
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
      *GNS-I                                                                    
           05  WS-RESPONSE-TIME.                                        01230000
               10  WS-RESPONSE-HOR       PIC  X(02) VALUE SPACES.       01240000
               10  WS-RESPONSE-MIN       PIC  X(02) VALUE SPACES.       01240000
               10  WS-RESPONSE-SEG       PIC  X(02) VALUE SPACES.       01240000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-CT-08             PIC X(02) VALUE '08'.               02000000
           05  WS-CT-09             PIC X(02) VALUE '09'.               02010000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-CT-O              PIC X(01) VALUE 'O'.                01970000
      *GNS-F                                                                    
           05  WS-CT-TRANSOK        PIC X(14)                           01971000
                                              VALUE 'TRANSACCION-OK'.   01972000
      *GNS-I                                                                    
           05  WS-CT-IM0304              PIC X(06) VALUE 'IM0304'.      02250000
           05  WS-CT-IM0316              PIC X(06) VALUE 'IM0316'.      02260000
           05  WS-CT-IM0504              PIC X(06) VALUE 'IM0504'.      02270000
           05  WS-CT-IM0604              PIC X(06) VALUE 'IM0604'.      02280000
           05  WS-CT-ST0316              PIC X(06) VALUE 'ST0316'.      02310000
           05  WS-CT-ST0404              PIC X(06) VALUE 'ST0404'.      02320000
           05  WS-CT-ST0604              PIC X(06) VALUE 'ST0604'.      02330000
      *GNS-F                                                                    
      *GNS-I                                                                    
           05  WS-CT-AG03                PIC X(04) VALUE 'AG03'.        02410000
           05  WS-CT-AC11                PIC X(04) VALUE 'AC11'.        02410000
           05  WS-CT-AC14                PIC X(04) VALUE 'AC14'.        02410000
           05  WS-CT-AC01                PIC X(04) VALUE 'AC01'.        02410000
           05  WS-CT-AC07                PIC X(04) VALUE 'AC07'.        02410000
           05  WS-CT-AC06                PIC X(04) VALUE 'AC06'.        02410000
           05  WS-CT-DNOR                PIC X(04) VALUE 'DNOR'.        02410000
           05  WS-CT-AM05                PIC X(04) VALUE 'AM05'.        02410000
      *GNS-F                                                                    
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
      *GNS-I                                                            02080000
      ** OPTIMIZACION CARACTERES ESPECIALES                             04631000
       01 WS-FINDREPLACE  PIC X(99) VALUE '‚ƒ‡·„ÂÁÒ¢ÈÍÎËÌÓÔÏﬂ¨¬ƒ¿¡√≈«¯… 00069579
      -           'À»ÕŒœÃ`ÿ˝Ê∆~›Æ^£•©ÙÚÛı˚¸˘˙ˇ‘÷“”’€‹Ÿ⁄!$;<>|¶%_?:="[]{}04633000
      -           '\—&@∞#()ø°*,.-/+'.                                   00069579
       01 WS-REPLACE      PIC X(99) VALUE 'AAAAAA N EEEEIIII  AAAAAA  EE00069579
      -           'EEIIII            oooouuuu OOOOOUUUU                 04636000
      -           ' NY              '.                                  00069579
      *GNS-F                                                            02080000
      *                                                                 02080000
       01  WS-CONTADORES-FILES.                                         02090000
           10 WS-NC-COUNTER-NAME    PIC  X(16) VALUE SPACES.            02100000
           10 WS-NRO-OPER-COUNTER        PIC S9(08)  COMP  VALUE +0.    02110000
       01  WS-RPTA-MSG.                                                 02120000
           05  WS-CODMSG-ESTRUCTURA.                                    02130000
               10  WS-CODAPP             PIC  X(02)  VALUE  'TI'.       02140000
               10  WS-CODMSG             PIC  X(04).                    02150000
           05  WS-TXTMSG                 PIC  X(80)  VALUE SPACES.      02160000
      *GNS-I                                                                    
           05  WS-COD-PROG              PIC  X(08) VALUE 'BCTITPR9'.    01940000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-BLQ-VP28               PIC  X(01)  VALUE  SPACES.     00160022
               88  WS-BLQ-VP28-ERR                   VALUE  'G', 'F',   00160022
                                           'A', 'M', 'O', 'U', 'Y'.     00160022
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-COD-E-LOG-EVENTOS       PIC  X(04) VALUE '0028'.              
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    05  WS-FILE-NM-MAESTRO-ALT2     PIC  X(08)  VALUE SPACES.    02739201
           05  WS-FILE-NM-MAESTRO-ALT3     PIC  X(08)  VALUE SPACES.    02739201
      *GNS-F                                                                    
           05  WS-FILE-NM-EVEN-LOG         PIC  X(08)  VALUE SPACES.    02739201
                                                                        02739301
      *GNS-I                                                                    
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
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    05  WS-CT-NUMER                PIC  X(04) VALUE SPACES.      02880000
           05  WS-TEMP-XXXX               PIC  X(04) VALUE SPACES.              
      *GNS-F                                                                    
           05  WS-TEMP-XX                 PIC  X(02) VALUE SPACES.      02881000
           05  WS-MENSAJE-TXT             PIC  X(80) VALUE SPACES.      02890000
           05  WS-MENSAJE-TXT-EVE         PIC  X(80)  VALUE SPACES.     02891000
           05  WS-CT-0                    PIC  9(01) VALUE 0.           02900000
           05  WS-CT-1                    PIC  9(01) VALUE 1.           02910000
           05  WS-CTN-12                  PIC  9(02) VALUE 12.          02911000
           05  WS-CT-1N                   PIC  9(01) VALUE 1.           02920000
      *GNS-I                                                                    
           05  WS-CT-2N                   PIC  9(01) VALUE 2.                   
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-TIPO-DOC-BEN-HOMOL      PIC  X(01) VALUE SPACES.      00570000
           05  INDOK                      PIC  9(02) VALUE ZEROS.               
           05  TIT                        PIC  9(02) VALUE ZEROS.               
      *GNS-F                                                                    
           05  WS-CT-SPACE4               PIC  X(04) VALUE SPACES.      03060000
           05  WS-CT-0001                 PIC  9(04) VALUE 0001.        03070000
           05  WS-EIBRESP                 PIC S9(08).                   03080000
           05  WS-EIBRESP2                PIC S9(08).                   03090000
           05  WS-CT-S                    PIC  X(01) VALUE 'S'.         03100000
           05  WS-CT-M                    PIC  X(01) VALUE 'M'.         03110000
           05  WS-CT-CTPB                 PIC  X(04) VALUE 'CTPB'.      03120000
           05  WS-CT-TPB                  PIC  X(03) VALUE 'TPB'.       03130000
           05  WS-CT-063                  PIC  X(03) VALUE '063'.       03140000
      *GNS-I                                                                    
           05  WS-CT-07C                  PIC  X(03) VALUE '007'.       00860000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           05  WS-88-ERROR-GRABAR-LOGEVEN PIC  X(80) VALUE              03530000
               'ERROR AL GRABAR EN LOG DE EVENTOS               '.      03540000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *COPY BCTICA02.                                                   04170001
       COPY BCTICAR2.                                                   04170001
      *GNS-F                                                                    
                                                                        04170101
      *--------------  COPY DE COMUNICACION PARA RUTINA DE MENSAJES     04171000
       COPY BCTICA15.                                                   04172000
                                                                        04170101
      *GNS-I                                                                    
      *--------------  MANTENIMIENTO ARCHIVO DE PARAMETROS              04681000
       COPY BCTICA80.                                                   04682000
      *GNS-F                                                                    
                                                                        04173000
      *-------------- COPY DE ARCHIVO LOG                               04180000
       COPY BCTICF07.                                                   04190000
                                                                        04191000
      *-------------- COPY DE ARCHIVO MAESTRO DE TRANSACCIONES          04200000
       COPY BCTICF06.                                                   04210000
                                                                        04211000
      *GNS-I                                                                    
      *-------------- COPY DE ARCHIVO DE REINTENTOS                     04200000
       COPY BCTICSEP.                                                   04210000
      *GNS-F                                                                    
      *-------------- COPY DE ARCHIVO DE PARAMETROS                     04220000
       COPY BCTICF01.                                                   04230000
                                                                        04230100
      *--------------  COPY TRAMA INPUT/OUTPUT NOVATRONICS              04231000
      *GNS-I                                                                    
      *COPY BCTITR02.                                                   04232000
       COPY BCTITRR2.                                                   04232000
      *GNS-F                                                                    
                                                                        04233000
      *-------------- COPY RUTINA DE ACCESO AL ARCHIVO DE PAR·METROS DE 04280000
       COPY BCRGCA05.                                                   04290000
                                                                        04291000
      *-------------- COPY RUTINA DE ASIGNACIÛN DIN·MICA DE USUARIO Y TE04300000
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
      *GNS-I                                                                    
      *01  DFHCOMMAREA                 PIC  X(2000).                    00160022
       01  DFHCOMMAREA                 PIC  X(4500).                    00160022
      *GNS-F                                                                    
                                                                        04451000
      *--------------  TABLA DEL SISTEMA TTIB ONLINE                    04452000
      *GNS-I                                                                    
      *COPY BCTICW03.                                                   04453000
       COPY BCTICW04.                                                   04453000
      *GNS-F                                                                    
                                                                        04454000
      ********************                                              04460000
       PROCEDURE DIVISION.                                              04470000
      ********************                                              04480000
                                                                        04490000
           PERFORM  1000-INICIO                                         04500000
                                                                        04510000
      *GNS-I                                                                    
      *    IF  WS-NO-EXISTE-ERROR                                       04520000
      *        PERFORM  3000-PROCESO                                    04530000
      *    END-IF                                                       04540000
           PERFORM  3000-PROCESO                                        04530000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    PERFORM  1005-OBTIENE-SYSID                                  04680000
      *GNS-F                                                                    
           PERFORM  1020-OBTIENE-FECHA-HORA-INICIO                      04690000
           PERFORM  1100-RECIBE-COMMAREA                                04700000
           PERFORM  1200-CARGA-TABLA-SIST-TTIB                          04710000
           PERFORM  1300-LEE-TRANSFERENCIA                              04711000
           PERFORM  1400-INVOCA-RUT-BCRGTP05                            04720000
           .                                                            04720100
      ************************ FIN DE 1000-INICIO                       04721000
      *GNS-I                                                                    
      ********************                                              04730000
      *1005-OBTIENE-SYSID.                                              04740000
      ********************                                              04741000
      ******************************************************************04742000
      * OBTIENE EL SYSID DEL CICS DONDE SE EJECUTA EL PROGRAMA         *04760000
      ******************************************************************04761000
      *                                                                 04780000
      *    EXEC  CICS  ASSIGN                                           04790000
      *          INVOKINGPROG (WS-PROG-CALLER)                          04800000
      *             STARTCODE (WS-TIPO-CONEX)                           04810000
      *                 SYSID (WS-SYSID-LOC)                            04820000
      *                USERID (WS-USUARIO)                              04830000
      *                  RESP (WS-RESP)                                 04840000
      *                 RESP2 (WS-RESP2)                                04850000
      *    END-EXEC                                                     04860000
      *                                                                 04870000
      *    IF  WS-RESP     NOT EQUAL TO    DFHRESP(NORMAL)              04880000
      *        SET  WS-SI-EXISTE-ERROR         TO TRUE                  04890000
      *        MOVE WS-COD-E-OBT-SYSID         TO WS-CODMSG             04900000
      *        MOVE WS-88-ERROR-OBT-SYSID      TO WS-TXTMSG             04910000
      *        PERFORM  6000-FINAL                                      04920000
      *                                                                 04921000
      *    END-IF                                                       04930000
      *    .                                                            04930100
      ************************ FIN DE 1005-OBTIENE-SYSID                04931000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        SET  WS-SI-EXISTE-ERROR        TO TRUE                   05070000
      *GNS-F                                                                    
               MOVE WS-COD-E-OBTIENE-FECHA    TO WS-CODMSG              05080000
               MOVE WS-88-ERROR-OBTIENE-FECHA TO WS-TXTMSG              05090000
      *GNS-I                                                                    
               MOVE WS-CODMSG-ESTRUCTURA      TO WS-CSMT-COD-RETORNO    05800000
               MOVE WS-COD-PROG               TO WS-CSMT-COD-PROGRAMA   05800000
               MOVE WS-TXTMSG                 TO WS-CSMT-MENSAJE        05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
               PERFORM 6000-FINAL                                       05680000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *         SET  WS-SI-EXISTE-ERROR     TO TRUE                     05220000
      *GNS-F                                                                    
                MOVE WS-COD-E-FORMATTIME    TO WS-CODMSG                05230000
                MOVE WS-88-ERROR-FORMATTIME TO WS-TXTMSG                05240000
      *GNS-I                                                                    
                MOVE WS-CODMSG-ESTRUCTURA   TO WS-CSMT-COD-RETORNO      05800000
                MOVE WS-COD-PROG            TO WS-CSMT-COD-PROGRAMA     05800000
                MOVE WS-TXTMSG              TO WS-CSMT-MENSAJE          05800000
                PERFORM 6400-WRITE-CSMT                                 00160022
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE DFHCOMMAREA            TO TI-CA02-AREA-COMUNICACION 00160022
      *        MOVE TI-CA02-REG-TRANS-DATA TO TI-TR02-I-TRAMA           00160022
      *                                                                 05341000
      *        MOVE TI-CA02-FILE-NAME-MAESTRO                           00160022
      *                                    TO WS-FILE-NM-MAESTRO        00160022
      *        MOVE TI-CA02-FILE-NAME-MAESTRO-ALT                       00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT    00160022
      *        MOVE TI-CA02-FILE-NAME-MAESTRO-ALT2                      00160022
      *                                    TO WS-FILE-NM-MAESTRO-ALT2   00160022
      *        MOVE TI-CA02-FILE-NAME-EVEN-LOG                          00160022
      *                                    TO WS-FILE-NM-EVEN-LOG       00160022
               MOVE DFHCOMMAREA            TO TI-CAR2-AREA-COMUNICACION 00160022
               MOVE TI-CAR2-REG-TRANS-DATA TO TI-TRR2-I-TRAMA           00160022
                                                                        00160022
               MOVE TI-CAR2-FILE-NAME-MAESTRO                           00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
               MOVE TI-CAR2-FILE-NAME-MAESTRO-ALT                       00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
               MOVE TI-CAR2-FILE-NAME-MAESTRO-ALT3                      00160022
                                           TO WS-FILE-NM-MAESTRO-ALT3   00160022
               MOVE TI-CAR2-FILE-NAME-EVEN-LOG                          00160022
                                           TO WS-FILE-NM-EVEN-LOG       00160022
      *GNS-F                                                                    
                                                                        05341000
           ELSE                                                         05350000
      *GNS-I                                                                    
      *        SET  WS-SI-EXISTE-ERROR   TO TRUE                        05360000
      *GNS-F                                                                    
               MOVE WS-COD-E-COMMAREA    TO WS-CODMSG                   05370000
               MOVE WS-88-ERROR-COMMAREA TO WS-TXTMSG                   05380000
      *GNS-I                                                                    
               MOVE WS-CODMSG-ESTRUCTURA TO WS-CSMT-COD-RETORNO         05800000
               MOVE WS-COD-PROG          TO WS-CSMT-COD-PROGRAMA        05800000
               MOVE WS-TXTMSG            TO WS-CSMT-MENSAJE             05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        SET  ADDRESS OF TI-CW03-REG-TABLA-SISTEMA                05403700
               SET  ADDRESS OF TI-CW04-REG-TABLA-SISTEMA                05403700
      *GNS-F                                                                    
                                           TO WS-PTR-TSIS               05403800
           ELSE                                                         05403900
      *        OBTENER MENSAJE PARA CCE                                 05404000
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05404100
      *                                                                 05404200
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      05404300
      *        SET  TI-CF06-88-RECH        TO TRUE                      05404400
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     05404500
                                          WS-TEMP-XX                    05404600
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    05404700
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     05404800
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    05404900
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   05405000
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                                          WS-TEMP-XXXX                          
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      05405100
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             05405200
      *                                                                 05405300
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     05405400
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 05480000
      *    MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         05490000
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   05500000
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       05510000
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       05520000
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        05530000
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 06120000
           MOVE TI-TRR2-CANAL              TO TI-CF06-CANAL-CCE         06130000
NO HAY     MOVE SPACES                     TO TI-CF06-BIN-ADQUIRIENTE   06140000
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       06150000
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          06160000
           MOVE WS-DATE-LOCAL              TO TI-CF06-FECHA-TRANS       06160000
           MOVE TI-TRR2-CREATION-TIME      TO TI-CF06-HORA-TRANS        06170000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *            IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201                00160022
      *                AND TI-TR02-COD-PROCESO  = WS-CT-490000          00160022
      *                AND TI-CF06-ESTADO = WS-CT-02                    00160022
      *                AND TI-CF06-COD-RESP-AMPLIADO = WS-CT-1021       00160022
      *                SET  TI-CF06-88-SI-REENV    TO TRUE              00160022
      *            ELSE                                                 00160022
      *GNS-F                                                                    
      *            OBTENER MENSAJE PARA CCE                             05772000
      *GNS-I                                                                    
      *                MOVE SPACES             TO TI-CA15-I-O-MENSAJES  05773000
      *                                                                 05774000
      *                SET  TI-CA15-I-RC-APP-CCE   TO TRUE              05775000
      *                SET  TI-CF06-88-RECH        TO TRUE              05776000
      *GNS-F                                                                    
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 05777000
                                              WS-TEMP-XX                05778000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)05779000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 05779100
                       MOVE WS-CT-AM05     TO TI-CF06-COD-RESP-AMPLIADO 05779100
      *GNS-I                                                                    
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)05779200
      *                MOVE WS-CT-1021     TO WS-CT-NUMER               05779300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX                      
      *GNS-F                                                                    
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  05779400
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *                PERFORM 6100-OBTENER-MENSAJE                     05779500
      *                                                                 05779600
      *                MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 05779700
      *GNS-F                                                                    
                                                                        05779800
      *            OBTENER MENSAJE INTERNO                              05779900
      *GNS-I                                                                    
      *                MOVE WS-CODMSG-ESTRUCTURA                        05780000
      *                                    TO WS-COD-ERROR-07           05780100
      *                MOVE WS-PROGRAM-ID  TO WS-PROGRAM                05780200
      *                                                                 05780500
      *                MOVE WS-MENSAJE-TXT TO WS-MENSAJE-TXT-EVE        05780400
      *GNS-F                                                                    
                                                                        05780600
                                                                        05780600
                       PERFORM 5600-ACTUALIZA-COMAREA                   05780700
      *GNS-I                                                                    
                       MOVE SPACES         TO TI-CA15-I-O-MENSAJES          0827
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  0827
                       MOVE 'TI0403'       TO TI-CF06-CODMSG-ESTRUCT        0827
                                              WS-CODMSG-ESTRUCTURA          0827
                                              WS-COD-ERROR-07               0827
                       MOVE WS-PROGRAM-ID  TO TI-CF06-PRGNOM                0827
                                              WS-PROGRAM                    0827
                       MOVE WS-CT-ESTADO   TO WS-VARMSG-RSO                 0016
                       MOVE TI-CF06-ESTADO TO WS-VARMSG-ARG                 0827
                                                                            0827
                       PERFORM 6100-OBTENER-MENSAJE                         0827
                       MOVE WS-MENSAJE-TXT TO TI-CF06-TXTMSG                0827
                                              WS-MENSAJE-TXT-EVE            0827
      *GNS-F                                                                    
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  05780800
                       PERFORM 6000-FINAL                               05780900
      *GNS-I                                                                    
      *            END-IF                                               00160022
      *GNS-F                                                                    
               END-IF                                                   05781000
                                                                        05782000
           ELSE                                                         05790000
               MOVE WS-RESP            TO WS-RESP-TXT                   05800000
      *        OBTENER MENSAJE PARA CCE                                 05872000
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      05873000
      *                                                                 05874000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      05875000
      *        SET  TI-CF06-88-RECH        TO TRUE                      05876000
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     05877000
                                          WS-TEMP-XX                    05878000
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    05879000
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     05879100
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    05879200
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   05879300
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                                          WS-TEMP-XXXX                          
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      05879400
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             05879500
      *                                                                 05879600
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     05879700
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06020000
      *                                                                 06030000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      06040000
      *        SET  TI-CF06-88-RECH        TO TRUE                      06050000
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 06060000
                                              WS-TEMP-XX                06070000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)06080000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 06090000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)06100000
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               06110000
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX                      
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  06120000
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             06130000
      *                                                                 06140000
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 06150000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             06260000
               MOVE WS-RTN-BCRGTP05        TO WS-VARMSG-RSO             06260000
      *GNS-F                                                                    
                                                                        06270000
               PERFORM 6100-OBTENER-MENSAJE                             06280000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            06290000
                                              WS-MENSAJE-TXT-EVE        06300000
                                                                        06310000
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     06311000
      *GNS-F                                                                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          06320000
               PERFORM 6000-FINAL                                       06330000
           ELSE                                                         06340000
               IF  RG-CA05-O-RET-NRO = WS-CT-0000                       06350000
                   CONTINUE                                             06360000
               ELSE                                                     06361000
      *            OBTENER MENSAJE PARA CCE                             06362000
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  06363000
      *                                                                 06364000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  06365000
      *            SET  TI-CF06-88-RECH        TO TRUE                  06366000
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 06367000
                                              WS-TEMP-XX                06368000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)06369000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 06369100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)06369200
      *            MOVE WS-CT-1021         TO WS-CT-NUMER               06369300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX                      
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  06369400
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         06369500
      *                                                                 06369600
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 06369700
      *GNS-F                                                                    
                                                                        06369800
      *            OBTENER MENSAJE INTERNO                              06369900
      *GNS-I                                                                    
      *            MOVE RG-CA05-O-RETORNO  TO TI-CF06-CODMSG-ESTRUCT    06370000
      *                                       WS-COD-ERROR-07           06370100
      *            MOVE WS-RTN-BCRGTP05    TO TI-CF06-PRGNOM            06370200
      *                                       WS-PROGRAM                06370300
      *            MOVE RG-CA05-O-MSJ-RET  TO TI-CF06-TXTMSG            06370400
      *                                       WS-MENSAJE-TXT-EVE        06370500
      *GNS-F                                                                    
                                                                        06370600
                   PERFORM 5600-ACTUALIZA-COMAREA                       06370700
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-RTN-BCRGTP05    TO WS-VARMSG-RSO             00160022
                   MOVE RG-CA05-O-RETORNO  TO WS-VARMSG-ARG             08272800
                   MOVE RG-CA05-O-MSJ-RET  TO WS-VARMSG-TXT             08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
      *GNS-F                                                                    
      *GNS-I                                                                    
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 06370800
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           EVALUATE TI-CAR2-COD-PROCESO-CNF-CAN                         07240000
              WHEN WS-CT-00                                             07250000
                   PERFORM 3050-PROCESO-CONFIRMADAS                     07260000
                                                                        07261000
              WHEN WS-CT-05                                             07270000
                   PERFORM 5900-PROCESO-CANCELADAS                      07280000
                                                                        07281000
              WHEN OTHER                                                07290000
      *            OBTENER MENSAJE PARA CCE                             07371000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 07376000
                                              WS-TEMP-XX                07377000
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 07379000
                                              WS-TEMP-XXXX              07379000
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  07379300
                                                                        07379700
      *            OBTENER MENSAJE INTERNO                              07379800
                   PERFORM 5600-ACTUALIZA-COMAREA                       07380700
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-CT-COD-PROCESO-CNF-CAN                       00160022
                                               TO WS-VARMSG-RSO         00160022
                   MOVE TI-CAR2-COD-PROCESO-CNF-CAN                     08272800
                                               TO WS-VARMSG-ARG         08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      07380800
                   PERFORM 6000-FINAL                                   07380900
           END-EVALUATE                                                 07381000
           .                                                            07381100
      ************************ FIN DE 3000-PROCESO                      07382000
      **************************                                        06371500
       3050-PROCESO-CONFIRMADAS.                                        07190000
      **************************                                        07191000
      ******************************************************************07192000
      * PROCESAMIENTO DEL PROGRAMA                                     *07210000
      ******************************************************************07211000
      *GNS-F                                                                    
                                                                        07230000
      *GNS-I                                                                    
      *    EVALUATE TI-TR02-TRANS-EXTENDIDA                             07240000
           EVALUATE TI-TRR2-TRANS-EXTENDIDA                             07240000
      *GNS-F                                                                    
              WHEN WS-CT-320                                            07250000
                   PERFORM 3100-TRANS-ORDINARIAS                        07260000
                                                                        07261000
              WHEN WS-CT-325                                            07270000
                   PERFORM 3400-PAGO-A-CUENTA-TCRE                      07280000
                                                                        07281000
              WHEN OTHER                                                07290000
      *            OBTENER MENSAJE PARA CCE                             07371000
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  07372000
      *                                                                 07373000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  07374000
      *            SET  TI-CF06-88-RECH        TO TRUE                  07375000
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 07376000
                                              WS-TEMP-XX                07377000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)07378000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 07379000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)07379100
      *            MOVE WS-CT-1006         TO WS-CT-NUMER               07379200
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-AG03         TO TI-CF06-COD-RESP-AMPLIADO 07379000
                                              WS-TEMP-XXXX              07379000
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  07379300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         07379400
      *                                                                 07379500
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 07379600
      *GNS-F                                                                    
                                                                        07379700
      *            OBTENER MENSAJE INTERNO                              07379800
      *GNS-I                                                                    
      *            MOVE WS-CODMSG-ESTRUCTURA                            07379900
      *                                    TO WS-COD-ERROR-07           07380000
      *            MOVE WS-PROGRAM-ID      TO WS-PROGRAM                07380100
      *                                                                 07380200
      *            MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        07380300
      *                                                                 07380400
      *                                                                 07380500
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 07380600
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       07380700
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-CT-TIPO-TRANSF  TO WS-VARMSG-RSO             00160022
                   MOVE TI-TRR2-TRANS-EXTENDIDA                         08272800
                                           TO WS-VARMSG-ARG             08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      07380800
                   PERFORM 6000-FINAL                                   07380900
           END-EVALUATE                                                 07381000
           .                                                            07381100
      ************************ FIN DE 3050-PROCESO-CONFIRMADAS          07382000
      ***********************                                           07383000
       3100-TRANS-ORDINARIAS.                                           07400000
      ***********************                                           07401000
      ******************************************************************07402000
      * PROCESAMIENTO DE TRANS-ORDINARIAS                              *07420000
      ******************************************************************07421000
                                                                        07440000
      *GNS-I                                                                    
      *    EVALUATE TI-TR02-CCI-CLI-BENEFICIA(16:1)                     07450000
           EVALUATE TI-TRR2-CCI-CLI-BENEFICIA(16:1)                     07450000
      *GNS-F                                                                    
              WHEN WS-CT-0                                              07460000
      *GNS-I                                                                    
      *          IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-604           07470000
                 IF TI-TRR2-TRANS-CURREN-CODE NOT = WS-CT-604           07470000
      *GNS-F                                                                    
      *             OBTENER MENSAJE PARA CCE                            07551000
      *GNS-I                                                                    
      *             MOVE SPACES                TO TI-CA15-I-O-MENSAJES  07552000
      *                                                                 07553000
      *             SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  07554000
      *             SET  TI-CF06-88-RECH       TO TRUE                  07555000
      *GNS-F                                                                    
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 07556000
                                              WS-TEMP-XX                07557000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)07558000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1009        TO TI-CF06-COD-RESP-AMPLIADO 07559000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)07559100
      *             MOVE WS-CT-1009        TO WS-CT-NUMER               07559200
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-AC11        TO TI-CF06-COD-RESP-AMPLIADO 07559000
                                              WS-TEMP-XXXX              07559000
      *GNS-F                                                                    
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  07559300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *             PERFORM 6100-OBTENER-MENSAJE                        07559400
      *                                                                 07559500
      *             MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 07559600
      *GNS-F                                                                    
                                                                        07559700
      *             OBTENER MENSAJE INTERNO                             07559800
      *GNS-I                                                                    
      *             MOVE WS-CODMSG-ESTRUCTURA                           07559900
      *                                    TO WS-COD-ERROR-07           07560000
      *             MOVE WS-PROGRAM-ID     TO WS-PROGRAM                07560100
      *                                                                 07560200
      *             MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        07560300
      *                                                                 07560400
      *                                                                 07560500
      *             PERFORM 5500-ACTUALIZA-MASTER-TRANSF                07560600
      *GNS-F                                                                    
                    PERFORM 5600-ACTUALIZA-COMAREA                      07560700
      *GNS-I                                                                    
                    MOVE SPACES             TO TI-CA15-I-O-MENSAJES     08271900
                    SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                 08272000
                    MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT   08272100
                                               WS-CODMSG-ESTRUCTURA     08272200
                                               WS-COD-ERROR-07          08272300
                    MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM           08272400
                                               WS-PROGRAM               08272500
                    MOVE WS-CT-MONEDA-CUENTA    TO WS-VARMSG-RSO        00160022
                    MOVE TI-TRR2-CCI-CLI-BENEFICIA(16:1)                08272800
                                                TO WS-VARMSG-ARG        08272800
                                                                        08272900
                    PERFORM 6100-OBTENER-MENSAJE                        08273000
                    MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG       08273100
                                                   WS-MENSAJE-TXT-EVE   08273200
      *GNS-F                                                                    
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     07560800
                    PERFORM 6000-FINAL                                  07560900
                                                                        07561000
                 END-IF                                                 07562000
      *                                                                 07570000
              WHEN WS-CT-1                                              07580000
      *GNS-I                                                                    
      *          IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-840           07590000
                 IF TI-TRR2-TRANS-CURREN-CODE NOT = WS-CT-840           07590000
      *GNS-F                                                                    
      *             OBTENER MENSAJE PARA CCE                            07671000
      *GNS-I                                                                    
      *             MOVE SPACES                TO TI-CA15-I-O-MENSAJES  07672000
      *                                                                 07673000
      *             SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  07674000
      *             SET  TI-CF06-88-RECH       TO TRUE                  07675000
      *GNS-F                                                                    
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 07676000
                                              WS-TEMP-XX                07677000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)07678000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1009        TO TI-CF06-COD-RESP-AMPLIADO 07679000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)07679100
      *             MOVE WS-CT-1009        TO WS-CT-NUMER               07679200
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-AC11        TO TI-CF06-COD-RESP-AMPLIADO 07679000
                                              WS-TEMP-XXXX              07679000
      *GNS-F                                                                    
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  07679300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *             PERFORM 6100-OBTENER-MENSAJE                        07679400
      *                                                                 07679500
      *             MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 07679600
      *GNS-F                                                                    
                                                                        07679700
      *             OBTENER MENSAJE INTERNO                             07679800
      *GNS-I                                                                    
      *             MOVE WS-CODMSG-ESTRUCTURA                           07679900
      *                                    TO WS-COD-ERROR-07           07680000
      *             MOVE WS-PROGRAM-ID     TO WS-PROGRAM                07680100
      *                                                                 07680200
      *             MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        07680300
      *                                                                 07680400
      *             PERFORM 5500-ACTUALIZA-MASTER-TRANSF                07680600
      *GNS-F                                                                    
                    PERFORM 5600-ACTUALIZA-COMAREA                      07680700
      *GNS-I                                                                    
                    MOVE SPACES             TO TI-CA15-I-O-MENSAJES     08271900
                    SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                 08272000
                    MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT   08272100
                                               WS-CODMSG-ESTRUCTURA     08272200
                                               WS-COD-ERROR-07          08272300
                    MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM           08272400
                                               WS-PROGRAM               08272500
                    MOVE WS-CT-MONEDA-CUENTA    TO WS-VARMSG-RSO        00160022
                    MOVE TI-TRR2-CCI-CLI-BENEFICIA(16:1)                08272800
                                                TO WS-VARMSG-ARG        08272800
                                                                        08272900
                    PERFORM 6100-OBTENER-MENSAJE                        08273000
                    MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG       08273100
                                                   WS-MENSAJE-TXT-EVE   08273200
      *GNS-F                                                                    
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     07680800
                    PERFORM 6000-FINAL                                  07680900
                                                                        07681000
                 END-IF                                                 07682000
      *                                                                 07690000
              WHEN OTHER                                                07700000
      *          OBTENER MENSAJE PARA CCE                               07781000
      *GNS-I                                                                    
      *          MOVE SPACES               TO TI-CA15-I-O-MENSAJES      07782000
      *                                                                 07783000
      *          SET  TI-CA15-I-RC-APP-CCE TO TRUE                      07784000
      *          SET  TI-CF06-88-RECH      TO TRUE                      07785000
      *GNS-F                                                                    
                 MOVE WS-CT-05             TO TI-CF06-RESPONSE-CODE-CCE 07786000
                                              WS-TEMP-XX                07787000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)07788000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *          MOVE WS-CT-1009           TO TI-CF06-COD-RESP-AMPLIADO 07789000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)07789100
      *          MOVE WS-CT-1009           TO WS-CT-NUMER               07789200
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                 MOVE WS-CT-AC11           TO TI-CF06-COD-RESP-AMPLIADO 07789000
                                              WS-TEMP-XXXX              07789000
      *GNS-F                                                                    
                 MOVE WS-CT-001            TO TI-CF06-ORIGEN-RESPUESTA  07789300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *          PERFORM 6100-OBTENER-MENSAJE                           07789400
      *                                                                 07789500
      *          MOVE WS-MENSAJE-TXT       TO TI-CF06-MENSAJE-RESPUESTA 07789600
      *GNS-F                                                                    
                                                                        07789700
      *          OBTENER MENSAJE INTERNO                                07789800
      *GNS-I                                                                    
      *          MOVE WS-CODMSG-ESTRUCTURA                              07789900
      *                                    TO WS-COD-ERROR-07           07790000
      *          MOVE WS-PROGRAM-ID        TO WS-PROGRAM                07790100
      *                                                                 07790200
      *          MOVE WS-MENSAJE-TXT       TO WS-MENSAJE-TXT-EVE        07790300
      *                                                                 07790400
      *          PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   07790500
      *GNS-F                                                                    
                 PERFORM 5600-ACTUALIZA-COMAREA                         07790600
      *GNS-I                                                                    
                 MOVE SPACES             TO TI-CA15-I-O-MENSAJES        08271900
                 SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                    08272000
                 MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT      08272100
                                            WS-CODMSG-ESTRUCTURA        08272200
                                            WS-COD-ERROR-07             08272300
                 MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM              08272400
                                            WS-PROGRAM                  08272500
                 MOVE WS-CT-MONEDA-CUENTA    TO WS-VARMSG-RSO           00160022
                 MOVE TI-TRR2-CCI-CLI-BENEFICIA(16:1)                   08272800
                                             TO WS-VARMSG-ARG           08272800
                                                                        08272900
                 PERFORM 6100-OBTENER-MENSAJE                           08273000
                 MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG          08273100
                                                WS-MENSAJE-TXT-EVE      08273200
      *GNS-F                                                                    
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        07790700
                 PERFORM 6000-FINAL                                     07790800
                                                                        07790900
           END-EVALUATE                                                 07792000
      *GNS-I                                                                    
           PERFORM 5000-VALIDA-CCI-BENEFICIARIO                         07790700
      *GNS-F                                                                    
      *                                                                 07800000
           MOVE WS-CT-4           TO DGC-IND-CLAVE                      07810000
      *GNS-I                                                                    
      *    IF TI-TR02-CCI-CLI-BENEFICIA(7:1) = WS-CT-0                  07820000
           IF TI-TRR2-CCI-CLI-BENEFICIA(7:1) = WS-CT-0                  07820000
      *GNS-F                                                                    
              MOVE 'CTE'          TO DGC-GLS-SERVICIO                   07830000
      *GNS-I                                                                    
      *       STRING TI-TR02-CCI-CLI-BENEFICIA(4:3)                     07840000
              STRING TI-TRR2-CCI-CLI-BENEFICIA(4:3)                     07840000
      *GNS-F                                                                    
                     WS-CT-0                                            07850000
      *GNS-I                                                                    
      *              TI-TR02-CCI-CLI-BENEFICIA(9:10)                    07860000
                     TI-TRR2-CCI-CLI-BENEFICIA(9:10)                    07860000
      *GNS-F                                                                    
                     DELIMITED BY SIZE INTO DGC-GLS-CLAVE               07870000
              END-STRING                                                07880000
           ELSE                                                         07890000
              MOVE 'AHO'       TO DGC-GLS-SERVICIO                      07900000
      *GNS-I                                                                    
      *       STRING TI-TR02-CCI-CLI-BENEFICIA(4:3)                     07910000
      *              TI-TR02-CCI-CLI-BENEFICIA(8:11)                    07920000
              STRING TI-TRR2-CCI-CLI-BENEFICIA(4:3)                     07910000
                     TI-TRR2-CCI-CLI-BENEFICIA(8:11)                    07920000
      *GNS-F                                                                    
                     DELIMITED BY SIZE INTO DGC-GLS-CLAVE               07930000
              END-STRING                                                07940000
           END-IF                                                       07950000
      *GNS-I                                                                    
      *    MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     07960000
           MOVE TI-TRR2-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     07960000
      *GNS-F                                                                    
      *GNS-I                                                                    
AJUSTA*    PERFORM 4155-HOMOLOGA-DOC                                    07970000
      *GNS-F                                                                    
           MOVE WS-TIPO-DOC-ORD-HOMOL    TO TI-CF06-TIP-DOC-CLI-ORIG    07971000
      *                                                                 07980000
           EXEC CICS LINK    PROGRAM(WS-RTN-SGCPPDGC)                   07990000
                             COMMAREA(SGCWGDGC)                         08000000
                             LENGTH(LENGTH OF SGCWGDGC)                 08010000
                             RESP(WS-RESP)                              08020000
                             END-EXEC                                   08030000
      *GNS-I                                                                    
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         14261000
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-TEMP-XXXX               14269300
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                                                        14269900
              PERFORM 5600-ACTUALIZA-COMAREA                            07790600
                                                                        14269900
      *       OBTENER MENSAJE INTERNO                                   14270000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     14270300
                                             WS-CODMSG-ESTRUCTURA       14270400
                                             WS-COD-ERROR-07            14270500
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             14270600
                                             WS-PROGRAM                 14270700
              MOVE 'LINK'                 TO WS-VARMSG-FUN              14270800
              MOVE WS-RTN-SGCPPDGC        TO WS-VARMSG-RSO              14270900
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 5700-GRABAR-LOG-EVENTOS                           07680800
              PERFORM 6000-FINAL                                        07680900
           END-IF                                                       14271700
      *GNS-F                                                                    
      *                                                                 08040000
           IF DGC-CRETORNO(1) = WS-CT-0000                              08050000
              MOVE WS-CT-1      TO IND                                  08060000
      *GNS-I                                                                    
                                   TIT                                          
      *GNS-F                                                                    
              MOVE 0            TO WS-CONTA                             08070000
              PERFORM UNTIL IND > 5 OR DGC-NUM-ICLI(IND) = SPACES       08080000
      *GNS-I                                                                    
                  IF DGC-CRETORNO(IND) EQUAL WS-CT-0000 AND             09390000
                     DGC-COD-RCOP(IND) EQUAL 'TCC'                      09390000
                      MOVE IND      TO TIT                              09440000
                      MOVE WS-CT-6  TO IND                              08332300
                  END-IF                                                09390000
                  ADD WS-CT-1N      TO IND                              08340000
              END-PERFORM                                               09420000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *               IF  DGC-COD-IRUC(IND)  =                          08331300
                      IF  DGC-COD-IRUC(TIT)  =                          08331300
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                                   TI-TR02-NRO-DOC-CLI-ORIG(1:11)08331400
                                          TI-TRR2-NRO-DOC-CLI-ORIG(1:11)08331400
      *GNS-F                                                                    
                          SET WS-ENCONTRADO-SI      TO TRUE             08331600
      *GNS-I                                                                    
      *                   STRING WS-CT-SPACE4                           08331700
      *                          DGC-NUM-ICLI(IND)                      08331800
      *                          DGC-IND-ICLI(IND)                      08331900
      *                          DGC-GLS-ICLI(IND)                      08332000
      *                          DELIMITED BY SIZE INTO WS-IDC          08332100
      *                   END-STRING                                    08332200
      *                   MOVE WS-CT-6              TO IND              08332300
      *GNS-F                                                                    
                                                                        08332400
                      END-IF                                            08332500
                                                                        08332600
                  WHEN "3"                                              08332700
                  WHEN "4"                                              08332800
                      MOVE SPACES              TO WS-DOC-ORD-TMP        08332900
      *GNS-I                                                                    
      *               MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        08333000
                      MOVE DGC-NUM-ICLI(TIT)   TO WS-DOC-ORD-TMP        08333000
      *GNS-F                                                                    
                      PERFORM 3900-REORDENAR-DOCUMENTO                  08333100
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    08333200
                                                                        08333300
                      MOVE SPACES              TO WS-DOC-ORD-TMP        08333400
      *GNS-I                                                                    
      *               MOVE TI-TR02-NRO-DOC-CLI-ORIG                     08333500
                      MOVE TI-TRR2-NRO-DOC-CLI-ORIG                     08333500
      *GNS-F                                                                    
                                               TO WS-DOC-ORD-TMP        08333600
                      PERFORM 3900-REORDENAR-DOCUMENTO                  08333700
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        08333800
                                                                        08333900
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 08334000
      *GNS-I                                                                    
      *                  AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  08334100
                         AND DGC-IND-ICLI(TIT) = WS-TIPO-DOC-ORD-HOMOL  08334100
      *GNS-F                                                                    
                         SET  WS-ENCONTRADO-SI    TO TRUE               08334200
      *GNS-I                                                                    
      *                  STRING WS-CT-SPACE4                            08334500
      *                         DGC-NUM-ICLI(IND)                       08334600
      *                         DGC-IND-ICLI(IND)                       08334700
      *                         DGC-GLS-ICLI(IND)                       08334800
      *                         DELIMITED BY SIZE INTO WS-IDC           08334900
      *                  END-STRING                                     08335000
      *                  MOVE WS-CT-6             TO IND                08335100
      *GNS-F                                                                    
                                                                        08335200
                      END-IF                                            08335300
                                                                        08335400
                  WHEN OTHER                                            08335500
      *GNS-I                                                                    
      *               IF DGC-NUM-ICLI(IND) =                            08335600
                      IF DGC-NUM-ICLI(TIT) =                            08335600
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                                    TI-TR02-NRO-DOC-CLI-ORIG(1:8)08335700
                                           TI-TRR2-NRO-DOC-CLI-ORIG(1:8)08335700
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                  AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  08335800
                         AND DGC-IND-ICLI(TIT) = WS-TIPO-DOC-ORD-HOMOL  08335800
      *GNS-F                                                                    
                         SET  WS-ENCONTRADO-SI    TO TRUE               08335900
      *GNS-I                                                                    
      *                  STRING WS-CT-SPACE4                            08336000
      *                         DGC-NUM-ICLI(IND)                       08336100
      *                         DGC-IND-ICLI(IND)                       08336200
      *                         DGC-GLS-ICLI(IND)                       08336300
      *                         DELIMITED BY SIZE INTO WS-IDC           08336400
      *                  END-STRING                                     08336500
      *                  MOVE WS-CT-6             TO IND                08336600
      *GNS-F                                                                    
                                                                        08336700
                      END-IF                                            08336800
                                                                        08336900
                END-EVALUATE                                            08337000
                                                                        08338000
      *GNS-I                                                                    
      *         ADD WS-CT-1N      TO IND                                08340000
      *       END-PERFORM                                               08350000
      *GNS-F                                                                    
      *GNS-I                                                            09650000
      *       IF  WS-ENCONTRADO-NO                                      08360000
      *           STRING WS-CT-SPACE4                                   08370000
      *                  DGC-NUM-ICLI(1)                                08380000
      *                  DGC-IND-ICLI(1)                                08390000
      *                  DGC-GLS-ICLI(1)                                08400000
      *                  DELIMITED BY SIZE INTO WS-IDC                  08410000
      *           END-STRING                                            08420000
      *       END-IF                                                    08430000
      *GNS-F                                                                    
      *GNS-I                                                                    
              IF WS-ENCONTRADO-SI                                       08360000
                  MOVE WS-CT-M TO TI-TRR2-INDI-MISMO-CLIENTE            09760000
              ELSE                                                      09670000
                  MOVE WS-CT-O TO TI-TRR2-INDI-MISMO-CLIENTE            09760000
              END-IF                                                    09670000
                                                                        09616000
              STRING WS-CT-SPACE4                                       09800000
                 DGC-NUM-ICLI(TIT)                                      09810000
                 DGC-IND-ICLI(TIT)                                      09820000
                 DGC-GLS-ICLI(TIT)                                      09830000
                 DELIMITED BY SIZE INTO WS-IDC                          09840000
              END-STRING                                                09850000
                                                                        09616000
              MOVE DGC-IND-ICLI(TIT) TO WS-TIPO-DOC-BEN-HOMOL           00      
              PERFORM 4156-HOMOLOGA-DOC-BEN                             00      
              MOVE WS-TIPO-DOC-BEN-HOMOL                                00      
                             TO TI-TRR2-TIP-DOC-CLI-BENE                00      
              IF DGC-IND-ICLI(TIT) EQUAL WS-CT-6                                
                  MOVE DGC-COD-IRUC(TIT)                                00      
                             TO TI-TRR2-NRO-DOC-CLI-BENE                00      
                  INSPECT DGC-GLS-NOMC(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-NOMC(TIT)                                00      
                             TO TI-TRR2-NOM-APE-BENE                    00      
              ELSE                                                              
                  MOVE DGC-NUM-ICLI(TIT)                                00      
                             TO TI-TRR2-NRO-DOC-CLI-BENE                00      
                  INSPECT DGC-GLS-NOMB(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-NOMB(TIT)                                00      
                             TO WS-DGC-GLS-NOMB-TMP                     00      
                  INSPECT DGC-GLS-APAT(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-APAT(TIT)                                00      
                             TO WS-DGC-GLS-APAT-TMP                     00      
                  INSPECT DGC-GLS-AMAT(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-AMAT(TIT)                                00      
                             TO WS-DGC-GLS-AMAT-TMP                     00      
                  STRING                                                        
                      WS-DGC-GLS-NOMB-TMP SPACE DELIMITED BY '   '              
                      WS-DGC-GLS-APAT-TMP SPACE DELIMITED BY '   '              
                      WS-DGC-GLS-AMAT-TMP SPACE DELIMITED BY '   '              
                                   INTO TI-TRR2-NOM-APE-BENE                    
                  END-STRING                                                    
              END-IF                                                            
      *GNS-F                                                                    
              MOVE WS-IDC                     TO TI-CF06-IDC-BEN        08431000
      *GNS-I                                                            09650000
AJUSTA        IF  DGC-NUM-ICLI(WS-CT-2N) NOT EQUAL (SPACES              10142000
                                                    AND LOW-VALUES      10142100
                                                    AND HIGH-VALUES)    10142200
                  OR INDOK > WS-CT-1N                                   10142300
                  MOVE WS-CT-O          TO TI-TRR2-INDI-MISMO-CLIENTE   10142400
                                                                        10143000
              END-IF                                                    10144000
      *GNS-F                                                            09650000
           ELSE                                                         08440000
             MOVE DGC-CRETORNO(1) TO WS-DGC-CRETORNO                    08450000
             EVALUATE WS-DGC-CRETORNO                                   08460000
                WHEN WS-CT-0001                                         08470000
                WHEN WS-CT-0002                                         08480000
                WHEN WS-CT-0003                                         08490000
                WHEN WS-CT-0009                                         08500000
      *            OBTENER MENSAJE PARA CCE                             08591000
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08592000
      *                                                                 08593000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08594000
      *            SET  TI-CF06-88-RECH        TO TRUE                  08595000
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08596000
                                              WS-TEMP-XX                08597000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)08598000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      **           MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)08599100
      **           MOVE WS-CT-1007         TO WS-CT-NUMER               00160022
      *            MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08599300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         08599400
      *                                                                 08599500
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08599600
      *GNS-F                                                                    
                                                                        08599700
      *            OBTENER MENSAJE INTERNO                              08599800
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08599900
      *                                       WS-COD-ERROR-07           08600000
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08600100
      *                                       WS-PROGRAM                08600200
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08600300
      *                                       WS-MENSAJE-TXT-EVE        08600400
      *                                                                 08600500
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08600900
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       08601000
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO             00160022
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG             08272800
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT             08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      08601100
                   PERFORM 6000-FINAL                                   08601200
                                                                        08601300
                WHEN WS-CT-2002                                         08602000
                WHEN WS-CT-2008                                         08610000
      *            OBTENER MENSAJE PARA CCE                             08620000
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08630000
      *                                                                 08640000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08650000
      *            SET  TI-CF06-88-RECH        TO TRUE                  08660000
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08670000
                                              WS-TEMP-XX                08680000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)08690000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO 08700000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)08710000
      *            MOVE WS-CT-1002         TO WS-CT-NUMER               08711000
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-AC01         TO TI-CF06-COD-RESP-AMPLIADO 08700000
                                              WS-TEMP-XXXX              08700000
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08711100
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         08711200
      *                                                                 08711300
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08711400
      *GNS-F                                                                    
                                                                        08711500
      *            OBTENER MENSAJE INTERNO                              08711600
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08711700
      *                                       WS-COD-ERROR-07           08711800
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08711900
      *                                       WS-PROGRAM                08712000
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08712100
      *                                       WS-MENSAJE-TXT-EVE        08712200
      *                                                                 08712300
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08712400
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       08712500
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES       0827190
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                   0827200
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO              0016002
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG              0827280
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT              0827280
                                                                         0827290
                   PERFORM 6100-OBTENER-MENSAJE                          0827300
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG         0827310
                                                  WS-MENSAJE-TXT-EVE     0827320
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      08712600
                   PERFORM 6000-FINAL                                   08712700
                                                                        08712800
                WHEN OTHER                                              08713000
      *            OBTENER MENSAJE PARA CCE                             08801000
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08802000
      *                                                                 08803000
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08804000
      *            SET  TI-CF06-88-RECH        TO TRUE                  08805000
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08806000
                                              WS-TEMP-XX                08807000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)08808000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      **           MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)08809100
      **           MOVE WS-CT-1008         TO WS-CT-NUMER               00160022
      *            MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-AC01         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08809300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         08809400
      *                                                                 08809500
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08809600
      *GNS-F                                                                    
                                                                        08809700
      *            OBTENER MENSAJE INTERNO                              08809800
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    08809900
      *                                       WS-COD-ERROR-07           08810000
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            08810100
      *                                       WS-PROGRAM                08810200
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            08810300
      *                                       WS-MENSAJE-TXT-EVE        08810400
      *                                                                 08810500
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 08810600
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       08810700
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES       0827190
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                   0827200
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO              0016002
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG              0827280
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT              0827280
                                                                         0827290
                   PERFORM 6100-OBTENER-MENSAJE                          0827300
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG         0827310
                                                  WS-MENSAJE-TXT-EVE     0827320
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *             MOVE SPACES                TO TI-CA15-I-O-MENSAJES  09142000
      *                                                                 09143000
      *             SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  09144000
      *             SET  TI-CF06-88-RECH       TO TRUE                  09145000
      *GNS-F                                                                    
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 09146000
                                              WS-TEMP-XX                09147000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)09148000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO 09149000
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)09149100
      *             MOVE WS-CT-1006        TO WS-CT-NUMER               09149200
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-1021        TO TI-CF06-COD-RESP-AMPLIADO 09149000
                                              WS-TEMP-XXXX              09149200
      *GNS-F                                                                    
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  09149300
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *             PERFORM 6100-OBTENER-MENSAJE                        09149400
      *                                                                 09149500
      *             MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 09149600
      *GNS-F                                                                    
                                                                        09149700
      *             OBTENER MENSAJE INTERNO                             09149800
      *GNS-I                                                                    
      *             MOVE WS-CODMSG-ESTRUCTURA                           09149900
      *                                    TO WS-COD-ERROR-07           09150000
      *             MOVE WS-PROGRAM-ID     TO WS-PROGRAM                09150100
      *                                                                 09150200
      *             MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        09150300
      *                                                                 09150400
      *                                                                 09150500
      *             PERFORM 5500-ACTUALIZA-MASTER-TRANSF                09150600
      *GNS-F                                                                    
                    PERFORM 5600-ACTUALIZA-COMAREA                      09150700
      *GNS-I                                                                    
                    MOVE SPACES             TO TI-CA15-I-O-MENSAJES      0827190
                    SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  0827200
                    MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT    0827210
                                               WS-CODMSG-ESTRUCTURA      0827220
                                               WS-COD-ERROR-07           0827230
                    MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            0827240
                                               WS-PROGRAM                0827250
                    MOVE WS-RTN-TABPQTPB    TO WS-VARMSG-RSO             0016002
                    MOVE OPB-GLS-RETO1      TO WS-VARMSG-ARG             0827280
                    MOVE OPB-GLS-RETO2      TO WS-VARMSG-TXT             0827280
                                                                         0827290
                    PERFORM 6100-OBTENER-MENSAJE                         0827300
                    MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        0827310
                                                   WS-MENSAJE-TXT-EVE    0827320
      *GNS-F                                                                    
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     09150800
                    PERFORM 6000-FINAL                                  09150900
                 END-IF                                                 09151000
              ELSE                                                      09160000
      *          OBTENER MENSAJE PARA CCE                               09261000
      *GNS-I                                                                    
      *          MOVE SPACES                TO TI-CA15-I-O-MENSAJES     09262000
      *                                                                 09263000
      *          SET  TI-CA15-I-RC-APP-CCE  TO TRUE                     09264000
      *          SET  TI-CF06-88-RECH       TO TRUE                     09265000
      *GNS-F                                                                    
                 MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE    09266000
                                           WS-TEMP-XX                   09267000
      *GNS-I                                                                    
      *                                    WS-CODMSG-ESTRUCTURA(1: 2)   09268000
      *                                    TI-TR02-RESPONSE-CODE-CCE            
      *          MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO    09269000
      *                                    WS-CODMSG-ESTRUCTURA(3: 4)   09269100
      *          MOVE WS-CT-1006        TO WS-CT-NUMER                  09269200
      *                                    TI-TR02-COD-RESP-AMPLIADO            
                 MOVE WS-CT-1021        TO TI-CF06-COD-RESP-AMPLIADO    09269000
                                           WS-TEMP-XXXX                 09269200
      *GNS-F                                                                    
                 MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA     09269300
      *GNS-I                                                                    
      *                                    TI-TR02-ORIGEN-RESPUESTA             
      *          PERFORM 6100-OBTENER-MENSAJE                           09269400
      *                                                                 09269500
      *          MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA    09269600
      *GNS-F                                                                    
                                                                        09269700
      *          OBTENER MENSAJE INTERNO                                09269800
      *GNS-I                                                                    
      *          MOVE WS-CODMSG-ESTRUCTURA                              09269900
      *                                 TO WS-COD-ERROR-07              09270000
      *          MOVE WS-PROGRAM-ID     TO WS-PROGRAM                   09270100
      *                                                                 09270200
      *          MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE           09270300
      *                                                                 09270400
      *                                                                 09270500
      *          PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   09270600
      *GNS-F                                                                    
                 PERFORM 5600-ACTUALIZA-COMAREA                         09270700
      *GNS-I                                                                    
                 MOVE SPACES             TO TI-CA15-I-O-MENSAJES         0827190
                 SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                     0827200
                 MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT       0827210
                                            WS-CODMSG-ESTRUCTURA         0827220
                                            WS-COD-ERROR-07              0827230
                 MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM               0827240
                                            WS-PROGRAM                   0827250
                 MOVE WS-RTN-TABPQTPB    TO WS-VARMSG-RSO                0016002
                 MOVE OPB-COD-RETO       TO WS-VARMSG-ARG                0827280
                 MOVE OPB-GLS-RETO       TO WS-VARMSG-TXT                0827280
                                                                         0827290
                 PERFORM 6100-OBTENER-MENSAJE                            0827300
                 MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
      *GNS-F                                                                    
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        09270800
                 PERFORM 6000-FINAL                                     09270900
              END-IF                                                    09271000
           ELSE                                                         09280000
      *       OBTENER MENSAJE PARA CCE                                  09491000
      *GNS-I                                                                    
      *       MOVE SPACES              TO TI-CA15-I-O-MENSAJES          09492000
      *                                                                 09493000
      *       SET  TI-CA15-I-RC-APP-CCE    TO TRUE                      09494000
      *       SET  TI-CF06-88-RECH         TO TRUE                      09495000
      *GNS-F                                                                    
              MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE         09496000
                                      WS-TEMP-XX                        09497000
      *GNS-I                                                                    
      *                               WS-CODMSG-ESTRUCTURA(1: 2)        09498000
      *                               TI-TR02-RESPONSE-CODE-CCE                 
      *GNS-F                                                                    
              MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO         09499000
      *GNS-I                                                                    
      *                               WS-CODMSG-ESTRUCTURA(3: 4)        09499100
      *       MOVE WS-CT-1021      TO WS-CT-NUMER                       09499200
      *                               TI-TR02-COD-RESP-AMPLIADO                 
                                      WS-TEMP-XXXX                      09499200
      *GNS-F                                                                    
              MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA          09499300
      *GNS-I                                                                    
      *                               TI-TR02-ORIGEN-RESPUESTA                  
      *       PERFORM 6100-OBTENER-MENSAJE                              09499400
      *                                                                 09499500
      *       MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA         09499600
      *GNS-F                                                                    
                                                                        09499700
      *       OBTENER MENSAJE INTERNO                                   09499800
      *GNS-I                                                                    
      *       MOVE OPB-COD-RETO    TO TI-CF06-CODMSG-ESTRUCT            09499900
      *                               WS-COD-ERROR-07                   09500000
      *       MOVE WS-RTN-TABPQTPB TO TI-CF06-PRGNOM                    09500100
      *                               WS-PROGRAM                        09500200
      *       MOVE OPB-GLS-RETO    TO TI-CF06-TXTMSG                    09500300
      *                               WS-MENSAJE-TXT-EVE                09500400
      *                                                                 09500500
      *       PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      09500600
      *GNS-F                                                                    
              PERFORM 5600-ACTUALIZA-COMAREA                            09500700
      *GNS-I                                                                    
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     14270300
                                             WS-CODMSG-ESTRUCTURA       14270400
                                             WS-COD-ERROR-07            14270500
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             14270600
                                             WS-PROGRAM                 14270700
              MOVE 'LINK'                 TO WS-VARMSG-FUN              14270800
              MOVE WS-RTN-TABPQTPB        TO WS-VARMSG-RSO              14270900
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)  TO TI-CF01-KEY04-BANCOS    09780000
           MOVE TI-TRR2-ENTIDAD-ORIGEN(2:3)  TO TI-CF01-KEY04-BANCOS    09780000
      *GNS-F                                                                    
           PERFORM 4100-EXTRAE-VALOR-PARAM                              09790000
      *                                                                 09800000
      *GNS-I                                                                    
      *TA000188752-I                                                            
      *    IF TI-TRR2-GLOSA EQUAL SPACES OR                                     
      *       TI-TRR2-GLOSA EQUAL LOW-VALUES                                    
      *TA000188752-F                                                            
      *GNS-F                                                                    
      *        STRING 'TRANSF.BCO.'                                     00014591
               STRING 'TRANSF.'                                         00014591
                      TI-CF01-BCOS-NOMBRE-CORTO                         09820000
                   DELIMITED BY SIZE INTO OQ-TR27-I-A-GLOSA1            09830000
               END-STRING                                               09840000
      *GNS-I                                                                    
JCS            MOVE  OQ-TR27-I-A-GLOSA1 TO  TI-CAR2-GLOSA-BCP                   
JCS                                         TI-TRR2-GLOSA-BCP                   
      *TA000188752-I                                                            
      *    ELSE                                                                 
      *        MOVE TI-TRR2-GLOSA      TO OQ-TR27-I-A-GLOSA1                    
      *    END-IF                                                               
      *TA000188752-F                                                            
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    EVALUATE TI-TR02-CCI-CLI-BENEFICIA(7:1)                      10030000
           EVALUATE TI-TRR2-CCI-CLI-BENEFICIA(7:1)                      10030000
      *GNS-F                                                                    
             WHEN WS-CTN-0                                              10040000
      *         GENERA NUMERO CTA.CTE                                   10060000
                INITIALIZE             OQ-TR27-I-A-NRO-MEDIO            10070000
                MOVE WS-0000000     TO OQ-TR27-I-A-NRO-MEDIO(1:7)       10080000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(04:3) TO                 10090000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(04:3) TO                 10090000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(8:3)       10100000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(09:7) TO                 10110000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(09:7) TO                 10110000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(11:7)      10120000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(16:1) TO                 10130000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(16:1) TO                 10130000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(18:1)      10140000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(17:2) TO                 10150000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(17:2) TO                 10150000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(19:2)      10160000
      *                                                                 10170000
      *GNS-I                                                                    
      *         IF TI-TR02-INDI-MISMO-CLIENTE = WS-CT-M                 10180000
                IF TI-TRR2-INDI-MISMO-CLIENTE = WS-CT-M                 10180000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(04:3) TO                 10360000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(04:3) TO                 10360000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(7:3)       10370000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(08:8) TO                 10380000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(08:8) TO                 10380000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(10:8)      10390000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(16:1) TO                 10400000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(16:1) TO                 10400000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(18:1)      10410000
      *GNS-I                                                                    
      *         MOVE TI-TR02-CCI-CLI-BENEFICIA(17:2) TO                 10420000
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(17:2) TO                 10420000
      *GNS-F                                                                    
                                       OQ-TR27-I-A-NRO-MEDIO(19:2)      10430000
      *                                                                 10440000
      *GNS-I                                                                    
      *         IF TI-TR02-INDI-MISMO-CLIENTE = 'M'                     10450000
                IF TI-TRR2-INDI-MISMO-CLIENTE = 'M'                     10450000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *         MOVE SPACES                TO TI-CA15-I-O-MENSAJES      10672000
      *                                                                 10673000
      *         SET  TI-CA15-I-RC-APP-CCE  TO TRUE                      10674000
      *         SET  TI-CF06-88-RECH       TO TRUE                      10675000
      *GNS-F                                                                    
                MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE     10676000
                                          WS-TEMP-XX                    10677000
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    10678000
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *                                                                         
      *         MOVE WS-CT-1016        TO TI-CF06-COD-RESP-AMPLIADO     10679000
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    10679100
      *         MOVE WS-CT-1016        TO WS-CT-NUMER                   10679200
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                MOVE WS-CT-AC14        TO TI-CF06-COD-RESP-AMPLIADO     10679000
                                          WS-TEMP-XXXX                  10679200
      *GNS-F                                                                    
                MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA      10679300
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *         PERFORM 6100-OBTENER-MENSAJE                            10679400
      *                                                                 10679500
      *         MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA     10679600
      *GNS-F                                                                    
                                                                        10679700
      *         OBTENER MENSAJE INTERNO                                 10679800
      *GNS-I                                                                    
      *         MOVE WS-CODMSG-ESTRUCTURA                               10679900
      *                                TO WS-COD-ERROR-07               10680000
      *         MOVE WS-PROGRAM-ID     TO WS-PROGRAM                    10680100
      *                                                                 10680200
      *         MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE            10680300
      *                                                                 10680400
      *         PERFORM 5500-ACTUALIZA-MASTER-TRANSF                    10680600
      *GNS-F                                                                    
                PERFORM 5600-ACTUALIZA-COMAREA                          10680700
      *GNS-I                                                                    
                MOVE SPACES             TO TI-CA15-I-O-MENSAJES         08271900
                SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                     08272000
                MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT       08272100
                                           WS-CODMSG-ESTRUCTURA         08272200
                                           WS-COD-ERROR-07              08272300
                MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM               08272400
                                           WS-PROGRAM                   08272500
                MOVE WS-CT-TIPO-CUENTA      TO WS-VARMSG-RSO            00160022
                MOVE TI-TRR2-CCI-CLI-BENEFICIA(7:1)                     08272800
                                            TO WS-VARMSG-ARG            08272800
                                                                        08272900
                PERFORM 6100-OBTENER-MENSAJE                            08273000
                MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG           08273100
                                               WS-MENSAJE-TXT-EVE       08273200
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      10923000
      *                                                                 10924000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      10925000
      *        SET  TI-CF06-88-RECH        TO TRUE                      10926000
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 10927000
                                              WS-TEMP-XX                10928000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)10929000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 10929100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)10929200
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               10929300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              10929300
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  10929400
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             10929500
      *                                                                 10929600
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 10929700
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     10931600
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *                MOVE SPACES             TO TI-CA15-I-O-MENSAJES  10932900
      *                                                                 10933000
      *                SET  TI-CA15-I-RC-APP-CCE   TO TRUE              10933100
      *                SET  TI-CF06-88-RECH        TO TRUE              10933200
      *GNS-F                                                                    
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 10933300
                                              WS-TEMP-XX                10933400
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)10933500
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *                MOVE WS-CT-1001     TO TI-CF06-COD-RESP-AMPLIADO 10933600
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)10933700
      *                MOVE WS-CT-1001     TO WS-CT-NUMER               10933800
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 10933600
                                              WS-TEMP-XXXX              10933800
      *GNS-F                                                                    
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  10933900
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *                PERFORM 6100-OBTENER-MENSAJE                     10934000
      *                                                                 10934100
      *                MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 10934200
      *GNS-F                                                                    
                                                                        10934300
      *                OBTENER MENSAJE INTERNO                          10934400
      *GNS-I                                                                    
      *                MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT10934500
      *                                           WS-COD-ERROR-07       10934600
      *                MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM        10934700
      *                                           WS-PROGRAM            10934800
      *                MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG        10934900
      *                                           WS-MENSAJE-TXT-EVE    10935000
      *                                                                 10935100
      *                PERFORM 5500-ACTUALIZA-MASTER-TRANSF             10935200
      *GNS-F                                                                    
                       PERFORM 5600-ACTUALIZA-COMAREA                   10935300
      *GNS-I                                                                    
                       MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200
                       MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210
                                                WS-CODMSG-ESTRUCTURA     0827220
                                                WS-COD-ERROR-07          0827230
                       MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240
                                                WS-PROGRAM               0827250
                       MOVE WS-BCOQTP10      TO WS-VARMSG-RSO            0016002
                       MOVE RG-CA10-O-RCODE                              0827280
                                             TO WS-VARMSG-ARG            0827280
                       MOVE RG-CA10-O-RC-MSG                             0827280
                                             TO WS-VARMSG-TXT            0827280
                                                                         0827290
                       PERFORM 6100-OBTENER-MENSAJE                      0827300
                       MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
      *GNS-F                                                                    
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  10935400
                       PERFORM 6000-FINAL                               10935500
                                                                        10935600
                                                                        10935700
                  WHEN OTHER                                            10935800
      *                OBTENER MENSAJE PARA CCE                         10935900
      *GNS-I                                                                    
      *                MOVE SPACES             TO TI-CA15-I-O-MENSAJES  10936000
      *                                                                 10936100
      *                SET  TI-CA15-I-RC-APP-CCE   TO TRUE              10936200
      *                SET  TI-CF06-88-RECH        TO TRUE              10936300
      *GNS-F                                                                    
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 10936400
                                              WS-TEMP-XX                10936500
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)10936600
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 10936700
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)10936800
      *                MOVE WS-CT-1021     TO WS-CT-NUMER               10936900
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              10936900
      *GNS-F                                                                    
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  10937000
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *                PERFORM 6100-OBTENER-MENSAJE                     10937100
      *                                                                 10937200
      *                MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 10937300
      *GNS-F                                                                    
                                                                        10937400
      *                OBTENER MENSAJE INTERNO                          10937500
      *GNS-I                                                                    
      *                MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT10937600
      *                                           WS-COD-ERROR-07       10937700
      *                MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM        10937800
      *                                           WS-PROGRAM            10937900
      *                MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG        10938000
      *                                           WS-MENSAJE-TXT-EVE    10938100
      *                                                                 10938200
      *                PERFORM 5500-ACTUALIZA-MASTER-TRANSF             10938300
      *GNS-F                                                                    
                       PERFORM 5600-ACTUALIZA-COMAREA                   10938400
      *GNS-I                                                                    
                       MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200
                       MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210
                                                WS-CODMSG-ESTRUCTURA     0827220
                                                WS-COD-ERROR-07          0827230
                       MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240
                                                WS-PROGRAM               0827250
                       MOVE WS-BCOQTP10      TO WS-VARMSG-RSO            0016002
                       MOVE RG-CA10-O-RCODE                              0827280
                                             TO WS-VARMSG-ARG            0827280
                       MOVE RG-CA10-O-RC-MSG                             0827280
                                             TO WS-VARMSG-TXT            0827280
                                                                         0827290
                       PERFORM 6100-OBTENER-MENSAJE                      0827300
                       MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE TI-TR02-COD-TARJETA-CRED(6:15)                      11050000
               MOVE TI-TRR2-COD-TARJETA-CRED(6:15)                      11050000
      *GNS-F                                                                    
                                           TO DGC-GLS-CLAVE(1:15)       11060000
               MOVE '0'                    TO DGC-GLS-CLAVE(16:1)       11070000
                                                                        11080000
           ELSE                                                         11090000
      *GNS-I                                                                    
      *        MOVE TI-TR02-COD-TARJETA-CRED(5:16)                      11110100
               MOVE TI-TRR2-COD-TARJETA-CRED(5:16)                      11110100
      *GNS-F                                                                    
                                           TO DGC-GLS-CLAVE(1:16)       11110200
                                                                        11110300
           END-IF                                                       11110400
                                                                        11110500
      *GNS-I                                                                    
      *    MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     11111000
           MOVE TI-TRR2-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     11111000
      *GNS-F                                                                    
      *GNS-I                                                                    
AJUSTA*    PERFORM 4155-HOMOLOGA-DOC                                    11120000
      *GNS-F                                                                    
           MOVE WS-TIPO-DOC-ORD-HOMOL      TO TI-CF06-TIP-DOC-CLI-ORIG  11121000
                                                                        11130000
           EXEC CICS LINK    PROGRAM(WS-RTN-SGCPPDGC)                   11131000
                             COMMAREA(SGCWGDGC)                         11132000
                             LENGTH(LENGTH OF SGCWGDGC)                 11133000
                             RESP(WS-RESP)                              11134000
                             END-EXEC                                   11135000
      *GNS-I                                                                    
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         14261000
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-TEMP-XXXX               14269300
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                                                        14269900
              PERFORM 5600-ACTUALIZA-COMAREA                            07790600
                                                                        14269900
      *       OBTENER MENSAJE INTERNO                                   14270000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     14270300
                                             WS-CODMSG-ESTRUCTURA       14270400
                                             WS-COD-ERROR-07            14270500
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             14270600
                                             WS-PROGRAM                 14270700
              MOVE 'LINK'                 TO WS-VARMSG-FUN              14270800
              MOVE WS-RTN-SGCPPDGC        TO WS-VARMSG-RSO              14270900
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 5700-GRABAR-LOG-EVENTOS                           07680800
              PERFORM 6000-FINAL                                        07680900
           END-IF                                                       14271700
      *GNS-F                                                                    
      *                                                                 11136000
           IF DGC-CRETORNO(1) = WS-CT-0000                              11137000
              MOVE WS-CT-1      TO IND                                  11138000
      *GNS-I                                                                    
                                   TIT                                  08060000
      *GNS-F                                                                    
              MOVE 0            TO WS-CONTA                             11139000
              PERFORM UNTIL IND > 5 OR DGC-NUM-ICLI(IND) = SPACES       11139100
      *GNS-I                                                                    
                  IF DGC-CRETORNO(IND) EQUAL WS-CT-0000 AND             09390000
                     DGC-COD-RCOP(IND) EQUAL 'TCC'                      09390000
                      MOVE IND      TO TIT                              09440000
                      MOVE WS-CT-6  TO IND                              08332300
                  END-IF                                                09390000
                  ADD WS-CT-1N      TO IND                              08340000
              END-PERFORM                                               09420000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *               IF  DGC-COD-IRUC(IND)  =                          11142000
                      IF  DGC-COD-IRUC(TIT)  =                          11142000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                                   TI-TR02-NRO-DOC-CLI-ORIG(1:11)11142100
                                          TI-TRR2-NRO-DOC-CLI-ORIG(1:11)11142100
      *GNS-F                                                                    
                          SET WS-ENCONTRADO-SI      TO TRUE             11142200
      *GNS-I                                                                    
      *                   STRING WS-CT-SPACE4                           11142300
      *                          DGC-NUM-ICLI(IND)                      11142400
      *                          DGC-IND-ICLI(IND)                      11142500
      *                          DGC-GLS-ICLI(IND)                      11142600
      *                          DELIMITED BY SIZE INTO WS-IDC          11142700
      *                   END-STRING                                    11142800
      *                   MOVE WS-CT-6              TO IND              11142900
      *GNS-F                                                                    
                                                                        11143000
                      END-IF                                            11143100
                                                                        11143200
                  WHEN "3"                                              11143300
                  WHEN "4"                                              11143400
                      MOVE SPACES              TO WS-DOC-ORD-TMP        11143500
      *GNS-I                                                                    
      *               MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        11143600
                      MOVE DGC-NUM-ICLI(TIT)   TO WS-DOC-ORD-TMP        11143600
      *GNS-F                                                                    
                      PERFORM 3900-REORDENAR-DOCUMENTO                  11143700
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    11143800
                                                                        11143900
                      MOVE SPACES              TO WS-DOC-ORD-TMP        11144000
      *GNS-I                                                                    
      *               MOVE TI-TR02-NRO-DOC-CLI-ORIG                     11144100
                      MOVE TI-TRR2-NRO-DOC-CLI-ORIG                     11144100
      *GNS-F                                                                    
                                               TO WS-DOC-ORD-TMP        11144200
                      PERFORM 3900-REORDENAR-DOCUMENTO                  11144300
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        11144400
                                                                        11144500
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 11144600
      *GNS-I                                                                    
      *                  AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  11144700
                         AND DGC-IND-ICLI(TIT) = WS-TIPO-DOC-ORD-HOMOL  11144700
      *GNS-F                                                                    
                         SET  WS-ENCONTRADO-SI    TO TRUE               11144800
      *GNS-I                                                                    
      *                  STRING WS-CT-SPACE4                            11144900
      *                         DGC-NUM-ICLI(IND)                       11145000
      *                         DGC-IND-ICLI(IND)                       11145100
      *                         DGC-GLS-ICLI(IND)                       11145200
      *                         DELIMITED BY SIZE INTO WS-IDC           11145300
      *                  END-STRING                                     11145400
      *                  MOVE WS-CT-6             TO IND                11145500
      *GNS-F                                                                    
                                                                        11145600
                      END-IF                                            11145700
                                                                        11145800
                  WHEN OTHER                                            11145900
      *GNS-I                                                                    
      *               IF DGC-NUM-ICLI(IND) =                            11146000
                      IF DGC-NUM-ICLI(TIT) =                            11146000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                                    TI-TR02-NRO-DOC-CLI-ORIG(1:8)11146100
                                           TI-TRR2-NRO-DOC-CLI-ORIG(1:8)11146100
      *GNS-F                                                                    
      *GNS-I                                                                    
      *                  AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  11146200
                         AND DGC-IND-ICLI(TIT) = WS-TIPO-DOC-ORD-HOMOL  11146200
      *GNS-F                                                                    
                         SET  WS-ENCONTRADO-SI    TO TRUE               11146300
      *GNS-I                                                                    
      *                  STRING WS-CT-SPACE4                            11146400
      *                         DGC-NUM-ICLI(IND)                       11146500
      *                         DGC-IND-ICLI(IND)                       11146600
      *                         DGC-GLS-ICLI(IND)                       11146700
      *                         DELIMITED BY SIZE INTO WS-IDC           11146800
      *                  END-STRING                                     11146900
      *                  MOVE WS-CT-6             TO IND                11147000
      *GNS-F                                                                    
                                                                        11147100
                      END-IF                                            11147200
                                                                        11147300
                END-EVALUATE                                            11147400
      *GNS-I                                                                    
      *         ADD WS-CT-1N      TO IND                                11147500
      *       END-PERFORM                                               11147600
      *GNS-F                                                                    
                                                                        11147700
      *GNS-I                                                            09650000
      *       IF  WS-ENCONTRADO-NO                                      11147800
      *           STRING WS-CT-SPACE4                                   11147900
      *                  DGC-NUM-ICLI(1)                                11148000
      *                  DGC-IND-ICLI(1)                                11148100
      *                  DGC-GLS-ICLI(1)                                11148200
      *                  DELIMITED BY SIZE INTO WS-IDC                  11148300
      *           END-STRING                                            11148400
      *       END-IF                                                    11148500
      *GNS-F                                                            09650000
      *GNS-I                                                                    
              IF WS-ENCONTRADO-SI                                       08360000
                  MOVE WS-CT-M TO TI-TRR2-INDI-MISMO-CLIENTE            09760000
              ELSE                                                      09670000
                  MOVE WS-CT-O TO TI-TRR2-INDI-MISMO-CLIENTE            09760000
              END-IF                                                    09670000
                                                                        09616000
              STRING WS-CT-SPACE4                                       09800000
                 DGC-NUM-ICLI(TIT)                                      09810000
                 DGC-IND-ICLI(TIT)                                      09820000
                 DGC-GLS-ICLI(TIT)                                      09830000
                 DELIMITED BY SIZE INTO WS-IDC                          09840000
              END-STRING                                                09850000
                                                                        09616000
              MOVE DGC-IND-ICLI(TIT) TO WS-TIPO-DOC-BEN-HOMOL           00      
              PERFORM 4156-HOMOLOGA-DOC-BEN                             00      
              MOVE WS-TIPO-DOC-BEN-HOMOL                                00      
                             TO TI-TRR2-TIP-DOC-CLI-BENE                00      
              IF DGC-IND-ICLI(TIT) EQUAL WS-CT-6                                
                  MOVE DGC-COD-IRUC(TIT)                                00      
                             TO TI-TRR2-NRO-DOC-CLI-BENE                00      
                  INSPECT DGC-GLS-NOMC(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-NOMC(TIT)                                00      
                             TO TI-TRR2-NOM-APE-BENE                    00      
              ELSE                                                              
                  MOVE DGC-NUM-ICLI(TIT)                                00      
                             TO TI-TRR2-NRO-DOC-CLI-BENE                00      
                  INSPECT DGC-GLS-NOMB(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-NOMB(TIT)                                00      
                             TO WS-DGC-GLS-NOMB-TMP                     00      
                  INSPECT DGC-GLS-APAT(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-APAT(TIT)                                00      
                             TO WS-DGC-GLS-APAT-TMP                     00      
                  INSPECT DGC-GLS-AMAT(TIT) CONVERTING                  00      
                           WS-FINDREPLACE TO WS-REPLACE                 00      
                  MOVE DGC-GLS-AMAT(TIT)                                00      
                             TO WS-DGC-GLS-AMAT-TMP                     00      
                  STRING                                                        
                      WS-DGC-GLS-NOMB-TMP SPACE DELIMITED BY '   '              
                      WS-DGC-GLS-APAT-TMP SPACE DELIMITED BY '   '              
                      WS-DGC-GLS-AMAT-TMP SPACE DELIMITED BY '   '              
                                   INTO TI-TRR2-NOM-APE-BENE                    
                  END-STRING                                                    
              END-IF                                                            
      *GNS-F                                                                    
              MOVE WS-IDC                     TO TI-CF06-IDC-BEN        11148600
      *GNS-I                                                            09650000
OJO??         MOVE WS-CT-O                 TO TI-TRR2-INDI-MISMO-CLIENTE        
      *GNS-F                                                            09650000
           ELSE                                                         11148700
             MOVE DGC-CRETORNO(1) TO WS-DGC-CRETORNO                    11148800
             EVALUATE WS-DGC-CRETORNO                                   11148900
                WHEN WS-CT-0001                                         11149000
                WHEN WS-CT-0002                                         11149100
                WHEN WS-CT-0003                                         11149200
                WHEN WS-CT-0009                                         11149300
      *            OBTENER MENSAJE PARA CCE                             11149400
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11149500
      *                                                                 11149600
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11149700
      *            SET  TI-CF06-88-RECH        TO TRUE                  11149800
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11149900
                                              WS-TEMP-XX                11150000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)11150100
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      **           MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)11150300
      **           MOVE WS-CT-1007         TO WS-CT-NUMER               00160022
      *            MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11150500
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         11150600
      *                                                                 11150700
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11150800
      *GNS-F                                                                    
                                                                        11150900
      *            OBTENER MENSAJE INTERNO                              11151000
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11151100
      *                                       WS-COD-ERROR-07           11151200
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11151300
      *                                       WS-PROGRAM                11151400
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11151500
      *                                       WS-MENSAJE-TXT-EVE        11151600
      *                                                                 11151700
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11151800
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       11151900
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO             00160022
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG             08272800
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT             08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11152000
                   PERFORM 6000-FINAL                                   11152100
                                                                        11152200
                WHEN WS-CT-2002                                         11152300
                WHEN WS-CT-2008                                         11152400
      *            OBTENER MENSAJE PARA CCE                             11152500
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11152600
      *                                                                 11152700
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11152800
      *            SET  TI-CF06-88-RECH        TO TRUE                  11152900
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11153000
                                              WS-TEMP-XX                11153100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)11153200
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO 11153300
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)11153400
      *            MOVE WS-CT-1002         TO WS-CT-NUMER               11153500
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-AC01         TO TI-CF06-COD-RESP-AMPLIADO 11153300
                                              WS-TEMP-XXXX              11153300
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11153600
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         11153700
      *                                                                 11153800
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11153900
      *GNS-F                                                                    
                                                                        11154000
      *            OBTENER MENSAJE INTERNO                              11154100
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11154200
      *                                       WS-COD-ERROR-07           11154300
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11154400
      *                                       WS-PROGRAM                11154500
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11154600
      *                                       WS-MENSAJE-TXT-EVE        11154700
      *                                                                 11154800
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11154900
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       11155000
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES       0827190
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                   0827200
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO              0016002
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG              0827280
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT              0827280
                                                                         0827290
                   PERFORM 6100-OBTENER-MENSAJE                          0827300
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG         0827310
                                                  WS-MENSAJE-TXT-EVE     0827320
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11155100
                   PERFORM 6000-FINAL                                   11155200
                                                                        11155300
                WHEN OTHER                                              11155400
      *            OBTENER MENSAJE PARA CCE                             11155500
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  11155600
      *                                                                 11155700
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  11155800
      *            SET  TI-CF06-88-RECH        TO TRUE                  11155900
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 11156000
                                              WS-TEMP-XX                11156100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)11156200
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      **           MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *            MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)11156400
      **           MOVE WS-CT-1008         TO WS-CT-NUMER               00160022
      *            MOVE WS-CT-1006         TO WS-CT-NUMER               00160022
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-AC01         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  11156600
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         11156700
      *                                                                 11156800
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 11156900
      *GNS-F                                                                    
                                                                        11157000
      *            OBTENER MENSAJE INTERNO                              11157100
      *GNS-I                                                                    
      *            MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    11157200
      *                                       WS-COD-ERROR-07           11157300
      *            MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            11157400
      *                                       WS-PROGRAM                11157500
      *            MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            11157600
      *                                       WS-MENSAJE-TXT-EVE        11157700
      *                                                                 11157800
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 11157900
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       11158000
      *GNS-I                                                                    
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES       0827190
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                   0827200
                   MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                   MOVE WS-RTN-SGCPPDGC    TO WS-VARMSG-RSO              0016002
                   MOVE DGC-CRETORNO(1)    TO WS-VARMSG-ARG              0827280
                   MOVE DGC-MSG-ERROR(1)   TO WS-VARMSG-TXT              0827280
                                                                         0827290
                   PERFORM 6100-OBTENER-MENSAJE                          0827300
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG         0827310
                                                  WS-MENSAJE-TXT-EVE     0827320
      *GNS-F                                                                    
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      11158100
                   PERFORM 6000-FINAL                                   11158200
                                                                        11158300
             END-EVALUATE                                               11158400
           END-IF                                                       11159000
      * *                                                               12050000
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
      *GNS-I                                                                    
      *             MOVE SPACES                TO TI-CA15-I-O-MENSAJES  12109800
      *                                                                 12109900
      *             SET  TI-CA15-I-RC-APP-CCE  TO TRUE                  12110000
      *             SET  TI-CF06-88-RECH       TO TRUE                  12110100
      *GNS-F                                                                    
                    MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE 12110200
                                              WS-TEMP-XX                12110300
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)12110400
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO 12110500
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)12110600
      *             MOVE WS-CT-1006        TO WS-CT-NUMER               12110700
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                    MOVE WS-CT-1021        TO TI-CF06-COD-RESP-AMPLIADO 12110500
                                              WS-TEMP-XXXX              12110700
      *GNS-F                                                                    
                    MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA  12110800
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *             PERFORM 6100-OBTENER-MENSAJE                        12110900
      *                                                                 12111000
      *             MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA 12111100
      *GNS-F                                                                    
                                                                        12111200
      *             OBTENER MENSAJE INTERNO                             12111300
      *GNS-I                                                                    
      *             MOVE WS-CODMSG-ESTRUCTURA                           12111400
      *                                    TO WS-COD-ERROR-07           12111500
      *             MOVE WS-PROGRAM-ID     TO WS-PROGRAM                12111600
      *                                                                 12111700
      *             MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE        12111800
      *                                                                 12111900
      *                                                                 12112000
      *             PERFORM 5500-ACTUALIZA-MASTER-TRANSF                12112100
      *GNS-F                                                                    
                    PERFORM 5600-ACTUALIZA-COMAREA                      12112200
      *GNS-I                                                                    
                    MOVE SPACES             TO TI-CA15-I-O-MENSAJES      0827190
                    SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  0827200
                    MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT    0827210
                                               WS-CODMSG-ESTRUCTURA      0827220
                                               WS-COD-ERROR-07           0827230
                    MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            0827240
                                               WS-PROGRAM                0827250
                    MOVE WS-RTN-TABPQTPB    TO WS-VARMSG-RSO             0016002
                    MOVE OPB-GLS-RETO1      TO WS-VARMSG-ARG             0827280
                    MOVE OPB-GLS-RETO2      TO WS-VARMSG-TXT             0827280
                                                                         0827290
                    PERFORM 6100-OBTENER-MENSAJE                         0827300
                    MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        0827310
                                                   WS-MENSAJE-TXT-EVE    0827320
      *GNS-F                                                                    
                    PERFORM 5700-GRABAR-LOG-EVENTOS                     12112300
                    PERFORM 6000-FINAL                                  12112400
                 END-IF                                                 12112500
              ELSE                                                      12112600
      *          OBTENER MENSAJE PARA CCE                               12112700
      *GNS-I                                                                    
      *          MOVE SPACES                TO TI-CA15-I-O-MENSAJES     12112800
      *                                                                 12112900
      *          SET  TI-CA15-I-RC-APP-CCE  TO TRUE                     12113000
      *          SET  TI-CF06-88-RECH       TO TRUE                     12113100
      *GNS-F                                                                    
                 MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE    12113200
                                           WS-TEMP-XX                   12113300
      *GNS-I                                                                    
      *                                    WS-CODMSG-ESTRUCTURA(1: 2)   12113400
      *                                    TI-TR02-RESPONSE-CODE-CCE            
      *          MOVE WS-CT-1006        TO TI-CF06-COD-RESP-AMPLIADO    12113500
      *                                    WS-CODMSG-ESTRUCTURA(3: 4)   12113600
      *          MOVE WS-CT-1006        TO WS-CT-NUMER                  12113700
      *                                    TI-TR02-COD-RESP-AMPLIADO            
                 MOVE WS-CT-1021        TO TI-CF06-COD-RESP-AMPLIADO    12113500
                                           WS-TEMP-XXXX                 12113700
      *GNS-F                                                                    
                 MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA     12113800
      *GNS-I                                                                    
      *                                    TI-TR02-ORIGEN-RESPUESTA             
      *          PERFORM 6100-OBTENER-MENSAJE                           12113900
      *                                                                 12114000
      *          MOVE WS-MENSAJE-TXT    TO TI-CF06-MENSAJE-RESPUESTA    12114100
      *GNS-F                                                                    
                                                                        12114200
      *          OBTENER MENSAJE INTERNO                                12114300
      *GNS-I                                                                    
      *          MOVE WS-CODMSG-ESTRUCTURA                              12114400
      *                                 TO WS-COD-ERROR-07              12114500
      *          MOVE WS-PROGRAM-ID     TO WS-PROGRAM                   12114600
      *                                                                 12114700
      *          MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE           12114800
      *                                                                 12114900
      *                                                                 12115000
      *          PERFORM 5500-ACTUALIZA-MASTER-TRANSF                   12115100
      *GNS-F                                                                    
                 PERFORM 5600-ACTUALIZA-COMAREA                         12115200
      *GNS-I                                                                    
                 MOVE SPACES             TO TI-CA15-I-O-MENSAJES         0827190
                 SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                     0827200
                 MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT       0827210
                                            WS-CODMSG-ESTRUCTURA         0827220
                                            WS-COD-ERROR-07              0827230
                 MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM               0827240
                                            WS-PROGRAM                   0827250
                 MOVE WS-RTN-TABPQTPB    TO WS-VARMSG-RSO                0016002
                 MOVE OPB-COD-RETO       TO WS-VARMSG-ARG                0827280
                 MOVE OPB-GLS-RETO       TO WS-VARMSG-TXT                0827280
                                                                         0827290
                 PERFORM 6100-OBTENER-MENSAJE                            0827300
                 MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
      *GNS-F                                                                    
                 PERFORM 5700-GRABAR-LOG-EVENTOS                        12115300
                 PERFORM 6000-FINAL                                     12115400
              END-IF                                                    12115500
           ELSE                                                         12115600
      *       OBTENER MENSAJE PARA CCE                                  12115700
      *GNS-I                                                                    
      *       MOVE SPACES              TO TI-CA15-I-O-MENSAJES          12115800
      *                                                                 12115900
      *       SET  TI-CA15-I-RC-APP-CCE    TO TRUE                      12116000
      *       SET  TI-CF06-88-RECH         TO TRUE                      12116100
      *GNS-F                                                                    
              MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE         12116200
                                      WS-TEMP-XX                        12116300
      *GNS-I                                                                    
      *                               WS-CODMSG-ESTRUCTURA(1: 2)        12116400
      *                               TI-TR02-RESPONSE-CODE-CCE                 
      *GNS-F                                                                    
              MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO         12116500
      *GNS-I                                                                    
      *                               WS-CODMSG-ESTRUCTURA(3: 4)        12116600
      *       MOVE WS-CT-1021      TO WS-CT-NUMER                       12116700
      *                               TI-TR02-COD-RESP-AMPLIADO                 
                                      WS-TEMP-XXXX                      12116700
      *GNS-F                                                                    
              MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA          12116800
      *GNS-I                                                                    
      *                               TI-TR02-ORIGEN-RESPUESTA                  
      *       PERFORM 6100-OBTENER-MENSAJE                              12116900
      *                                                                 12117000
      *       MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA         12117100
      *GNS-F                                                                    
                                                                        12117200
      *       OBTENER MENSAJE INTERNO                                   12117300
      *GNS-I                                                                    
      *       MOVE OPB-COD-RETO    TO TI-CF06-CODMSG-ESTRUCT            12117400
      *                               WS-COD-ERROR-07                   12117500
      *       MOVE WS-RTN-TABPQTPB TO TI-CF06-PRGNOM                    12117600
      *                               WS-PROGRAM                        12117700
      *       MOVE OPB-GLS-RETO    TO TI-CF06-TXTMSG                    12117800
      *                               WS-MENSAJE-TXT-EVE                12117900
      *                                                                 12118000
      *       PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      12118100
      *GNS-F                                                                    
              PERFORM 5600-ACTUALIZA-COMAREA                            12118200
      *GNS-I                                                                    
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14270100
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       14270200
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     14270300
                                             WS-CODMSG-ESTRUCTURA       14270400
                                             WS-COD-ERROR-07            14270500
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             14270600
                                             WS-PROGRAM                 14270700
              MOVE 'LINK'                 TO WS-VARMSG-FUN              14270800
              MOVE WS-RTN-TABPQTPB        TO WS-VARMSG-RSO              14270900
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
      *GNS-F                                                                    
              PERFORM 5700-GRABAR-LOG-EVENTOS                           12118300
              PERFORM 6000-FINAL                                        12118400
           END-IF                                                       12118500
      *    CARGA CABECERA DE ORQUESTADOR                                12700000
           PERFORM 5000-CARGA-CABECERA                                  12710000
      *                                                                 12720000
           PERFORM 5100-CARGA-DETALLES                                  12730000
                                                                        12740000
           MOVE SPACES                     TO TI-CF01-KEY04             12750000
           MOVE '04'                       TO TI-CF01-KEY04-TIP-PRM     12760000
      *GNS-I                                                                    
      *    MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)TO TI-CF01-KEY04-BANCOS      12770000
           MOVE TI-TRR2-ENTIDAD-ORIGEN(2:3)TO TI-CF01-KEY04-BANCOS      12770000
      *GNS-F                                                                    
           PERFORM 4100-EXTRAE-VALOR-PARAM                              12780000
      *                                                                 12790000
      *GNS-I                                                                    
      *TA000188752-I                                                            
      *    IF TI-TRR2-GLOSA EQUAL SPACES OR                                     
      *       TI-TRR2-GLOSA EQUAL LOW-VALUES                                    
      *TA000188752-F                                                            
      *GNS-F                                                                    
      *        STRING  'PAGO A CTA.BCO.'                                00014591
               STRING  'PAGO TC.'                                       00014591
                       TI-CF01-BCOS-NOMBRE-CORTO                        12810000
                   DELIMITED BY SIZE INTO OQ-TR27-I-A-GLOSA1            12820000
               END-STRING                                               12830000
JCS            MOVE  OQ-TR27-I-A-GLOSA1   TO  TI-CAR2-GLOSA-BCP                 
JCS                                           TI-TRR2-GLOSA-BCP                 
      *GNS-I                                                                    
      *TA000188752-I                                                            
      *    ELSE                                                                 
      *        MOVE TI-TRR2-GLOSA      TO OQ-TR27-I-A-GLOSA1                    
      *    END-IF                                                               
      *TA000188752-F                                                            
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-IMPORTE(1:10)  TO WS-SOLES(5:10)                13000000
           MOVE TI-TRR2-IMPORTE(1:10)  TO WS-SOLES(5:10)                13000000
      *GNS-F                                                                    
           MOVE '.'                    TO WS-PUNTO                      13010000
      *GNS-I                                                                    
      *    MOVE TI-TR02-IMPORTE(11:2)  TO WS-CENTI(1:2)                 13020000
           MOVE TI-TRR2-IMPORTE(11:2)  TO WS-CENTI(1:2)                 13020000
      *GNS-F                                                                    
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-IMP-OPE             13030000
      *                                                                 13040000
      * SI COBRA COMISION A TC.                                         13050000
           MOVE 'CCE'                  TO OQ-TR27-I-A-CAUSAL-TC         13060000
           MOVE ZEROS                  TO WS-SOLES WS-CENTI             13070000
           MOVE SPACES                 TO WS-SIGNO                      13080000
           MOVE '.'                    TO WS-PUNTO                      13090000
      *GNS-I                                                                    
      *    MOVE TI-TR02-IMPORTE-COMISION(1:13) TO WS-SOLES(2:13)        13100000
      *    MOVE TI-TR02-IMPORTE-COMISION(14:2) TO WS-CENTI(1:2)         13110000
           MOVE TI-TRR2-IMPORTE-COMISION(1:13) TO WS-SOLES(2:13)        13100000
           MOVE TI-TRR2-IMPORTE-COMISION(14:2) TO WS-CENTI(1:2)         13110000
      *GNS-F                                                                    
           MOVE 'TCRE'                 TO OQ-TR27-I-A-COD-ABONO         13120000
           MOVE WS-IMPORTE-20          TO OQ-TR27-I-A-IMP-COM-TC        13130000
           MOVE 'S'                    TO OQ-TR27-I-A-FLG-COMISION-TC   13140000
      *                                                                 13150000
           IF  OQ-TR27-I-A-COD-FAM = WS-003                             13160000
               AND OQ-TR27-I-A-COD-PRO = WS-014                         13170000
      *        TC AMEX                                                  13180000
               INITIALIZE OQ-TR27-I-A-NRO-MEDIO                         13190000
               MOVE WS-0000            TO OQ-TR27-I-A-NRO-MEDIO(2:4)    13200000
      *GNS-I                                                                    
      *        MOVE TI-TR02-COD-TARJETA-CRED(6:15)                      13210000
               MOVE TI-TRR2-COD-TARJETA-CRED(6:15)                      13210000
      *GNS-F                                                                    
                                       TO OQ-TR27-I-A-NRO-MEDIO(6:15)   13220000
                                                                        13221000
           ELSE                                                         13230000
      *        TC VISA / MASTERCARD                                     13240000
               IF  OQ-TR27-I-A-COD-FAM = WS-003 AND                     13250000
                   (OQ-TR27-I-A-COD-PRO = WS-013 OR                     13260000
                   OQ-TR27-I-A-COD-PRO = WS-082)                        13270000
                   INITIALIZE OQ-TR27-I-A-NRO-MEDIO                     13280000
                   MOVE WS-000         TO OQ-TR27-I-A-NRO-MEDIO(2:3)    13290000
      *GNS-I                                                                    
      *            MOVE TI-TR02-COD-TARJETA-CRED(5:16)                  13300000
                   MOVE TI-TRR2-COD-TARJETA-CRED(5:16)                  13300000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      13613000
      *                                                                 13614000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      13615000
      *        SET  TI-CF06-88-RECH        TO TRUE                      13616000
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 13617000
                                              WS-TEMP-XX                13618000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)13619000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 13619100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)13619200
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               13619300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              13619300
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  13619400
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             13619500
      *                                                                 13619600
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 13619700
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     13621500
      *GNS-F                                                                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          13621600
               PERFORM 6000-FINAL                                       13621700
           ELSE                                                         13621800
               MOVE OQ-TR27-O-HDR      TO RG-CA10-O-OUTPUT-CANAL-HEADER 13621900
               IF  RG-CA10-O-RCODE = 'OQ0000'                           13622000
                   CONTINUE                                             13622100
               ELSE                                                     13622200
      *            OBTENER MENSAJE PARA CCE                             13622300
      *GNS-I                                                                    
      *            MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  13622400
      *                                                                 13622500
      *            SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  13622600
      *            SET  TI-CF06-88-RECH        TO TRUE                  13622700
      *GNS-F                                                                    
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 13622800
                                              WS-TEMP-XX                13622900
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)13623000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 13623100
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)13623200
      *            MOVE WS-CT-1021         TO WS-CT-NUMER               13623300
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              13623300
      *GNS-F                                                                    
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  13623400
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *            PERFORM 6100-OBTENER-MENSAJE                         13623500
      *                                                                 13623600
      *            MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 13623700
      *GNS-F                                                                    
                                                                        13623800
      *            OBTENER MENSAJE INTERNO                              13623900
      *GNS-I                                                                    
      *            MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT    13624000
      *                                       WS-COD-ERROR-07           13624100
      *            MOVE WS-BCOQTP10        TO TI-CF06-PRGNOM            13624200
      *                                       WS-PROGRAM                13624300
      *            MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG            13624400
      *                                       WS-MENSAJE-TXT-EVE        13624500
      *                                                                 13624600
      *            PERFORM 5500-ACTUALIZA-MASTER-TRANSF                 13624700
      *GNS-F                                                                    
                   PERFORM 5600-ACTUALIZA-COMAREA                       13624800
      *GNS-I                                                                    
                   MOVE SPACES           TO TI-CA15-I-O-MENSAJES         0827190
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                   0827200
                   MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT       0827210
                                            WS-CODMSG-ESTRUCTURA         0827220
                                            WS-COD-ERROR-07              0827230
                   MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM               0827240
                                            WS-PROGRAM                   0827250
                   MOVE WS-BCOQTP10      TO WS-VARMSG-RSO                0016002
                   MOVE RG-CA10-O-RCODE                                  0827280
                                         TO WS-VARMSG-ARG                0827280
                   MOVE RG-CA10-O-RC-MSG                                 0827280
                                         TO WS-VARMSG-TXT                0827280
                                                                         0827290
                   PERFORM 6100-OBTENER-MENSAJE                          0827300
                   MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG               0827310
                                            WS-MENSAJE-TXT-EVE           0827320
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-CW03-CANAL              TO RG-CA10-I-CANAL-APL       13649000
           MOVE TI-CW04-CANAL              TO RG-CA10-I-CANAL-APL       13649000
      *GNS-F                                                                    
           MOVE RG-CA05-O-0A-AMBIENTE      TO RG-CA10-I-CANAL-AMB       13649100
           MOVE ZEROS                      TO WS-NRO-OPERACION          13649200
      *GNS-I                                                                    
      *    MOVE TI-TR02-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     13649300
           MOVE TI-CAR2-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     13649300
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-COD-TARJETA-CRED(2:19) TO VP-COM-CODTAR         13650600
           MOVE TI-TRR2-COD-TARJETA-CRED(2:19) TO VP-COM-CODTAR         13650600
      *GNS-F                                                                    
           MOVE 'SL'                       TO VP-COM-TRANSAC            13650700
                                                                        13650800
      *TA000188957-I                                                            
      *    PERFORM 5200-ASIGNAR-TERM-USER                               13650900
      *    MOVE RG-CA04-I-HDR-STD-IN   TO RG-CA10-I-INPUT-CANAL-HEADER  13651000
      *                                   VP-I-O-HEADER-ESTANDAR        13651100
           MOVE 'IR99'                 TO RG-CA10-I-TERM-CICS-TETI      10951100
           MOVE 'IR0099'               TO RG-CA10-I-K-USR-CODIGO        10951100
           MOVE RG-CA10-I-INPUT-CANAL-HEADER                            13651000
                                       TO VP-I-O-HEADER-ESTANDAR        13651100
      *TA000188957-F                                                            
      *                                                                 13651200
      *GNS-I                                                                    
      *    EXEC CICS LINK PROGRAM  (TI-CW03-SRV-VP28)                   13651300
           EXEC CICS LINK PROGRAM  (TI-CW04-SRV-VP28)                   13651300
      *GNS-F                                                                    
                          COMMAREA (VP-AREA-DATOS-N)                    13651400
                          LENGTH   (LENGTH OF VP-AREA-DATOS-N)          13651500
                          NOHANDLE                                      13651600
                          RESP(WS-RESP)                                 13651700
           END-EXEC.                                                    13651800
      *                                                                 13651900
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         13652000
      *       OBTENER MENSAJE PARA CCE                                  13652100
      *GNS-I                                                                    
      *       MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       13652200
      *                                                                 13652300
      *       SET  TI-CA15-I-RC-APP-CCE   TO TRUE                       13652400
      *       SET  TI-CF06-88-RECH        TO TRUE                       13652500
      *GNS-F                                                                    
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  13652600
                                             WS-TEMP-XX                 13652700
      *GNS-I                                                                    
      *                                      WS-CODMSG-ESTRUCTURA(1: 2) 13652800
      *                                      TI-TR02-RESPONSE-CODE-CCE          
      *GNS-F                                                                    
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  13652900
      *GNS-I                                                                    
      *                                      WS-CODMSG-ESTRUCTURA(3: 4) 13653000
      *       MOVE WS-CT-1021             TO WS-CT-NUMER                13653100
      *                                      TI-TR02-COD-RESP-AMPLIADO          
                                             WS-TEMP-XXXX                       
      *GNS-F                                                                    
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   13653200
      *GNS-I                                                                    
      *                                      TI-TR02-ORIGEN-RESPUESTA           
      *       PERFORM 6100-OBTENER-MENSAJE                              13653300
      *                                                                 13653400
      *       MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA  13653500
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *       MOVE TI-CW03-SRV-VP28       TO WS-VARMSG-RSO              13654700
              MOVE TI-CW04-SRV-VP28       TO WS-VARMSG-RSO              13654700
      *GNS-F                                                                    
                                                                        13654800
              PERFORM 6100-OBTENER-MENSAJE                              13654900
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             13655000
                                             WS-MENSAJE-TXT-EVE         13655100
                                                                        13655200
      *GNS-I                                                                    
      *       PERFORM 5500-ACTUALIZA-MASTER-TRANSF                      13655300
      *GNS-F                                                                    
              PERFORM 5700-GRABAR-LOG-EVENTOS                           13655400
              PERFORM 6000-FINAL                                        13655500
           END-IF                                                       13655600
      *GNS-I                                                                    
           MOVE VP-I-O-HEADER-ESTANDAR TO RG-CA10-O-OUTPUT-CANAL-HEADER 14272000
                                                                        14280000
           IF (RG-CA10-O-RC-TIP = WS-CT-00 AND                          14290000
               RG-CA10-O-RC-SEC = WS-CT-00)                             14300000
               MOVE VP-CODBLQ              TO WS-BLQ-VP28               00160022
               IF  WS-BLQ-VP28-ERR                                      00160022
      *            OBTENER MENSAJE PARA CCE                             00160022
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 00160022
                                              WS-TEMP-XX                00160022
                   MOVE WS-CT-AC06         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  00160022
                                                                        00160022
      *            OBTENER MENSAJE INTERNO                              00160022
                                                                        00160022
                                                                        00160022
                   PERFORM 5600-ACTUALIZA-COMAREA                       00160022
                   MOVE SPACES           TO TI-CA15-I-O-MENSAJES        0827190 
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  0827200 
                   MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT      0827210 
                                            WS-CODMSG-ESTRUCTURA        0827220 
                                            WS-COD-ERROR-07             0827230 
                   MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM              0827240 
                                            WS-PROGRAM                  0827250 
                   MOVE TI-CW04-SRV-VP28 TO WS-VARMSG-RSO               0016002 
                   MOVE RG-CA10-O-RCODE  TO WS-VARMSG-ARG               0827280 
                   MOVE VP-CODBLQ        TO WS-VARMSG-TXT               0827280 
                                                                        0827290 
                   PERFORM 6100-OBTENER-MENSAJE                         0827300 
                   MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG              0827310 
                                            WS-MENSAJE-TXT-EVE          0827320 
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      00160022
                   PERFORM 6000-FINAL                                   00160022
                                                                        00160022
               END-IF                                                   00160022
                                                                        00160022
               IF VP-FBINMON = 'N'                                      14310000
                  EVALUATE VP-COD-MON-DUAL                              14320000
                  WHEN WS-CT-0001                                       14330000
                     IF TI-TRR2-TRANS-CURREN-CODE NOT = WS-CT-604       14340000
      *                 OBTENER MENSAJE PARA CCE                        14461000
                        MOVE WS-CT-05      TO TI-CF06-RESPONSE-CODE-CCE 14466000
                                              WS-TEMP-XX                14467000
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                        MOVE WS-CT-AC11    TO TI-CF06-COD-RESP-AMPLIADO 14469000
                                              WS-TEMP-XXXX              14469200
                        MOVE WS-CT-001     TO TI-CF06-ORIGEN-RESPUESTA  14469300
                                                                        14469800
      *                 OBTENER MENSAJE INTERNO                         14469900
                                                                        14470500
                                                                        14470600
                        PERFORM 5600-ACTUALIZA-COMAREA                  14470700
                        MOVE SPACES           TO TI-CA15-I-O-MENSAJES   0827190 
                        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE             0827200 
                        MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT 0827210 
                                                 WS-CODMSG-ESTRUCTURA   0827220 
                                                 WS-COD-ERROR-07        0827230 
                        MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM         0827240 
                                                 WS-PROGRAM             0827250 
                        MOVE TI-CW04-SRV-VP28 TO WS-VARMSG-RSO          0016002 
                        MOVE RG-CA10-O-RCODE  TO WS-VARMSG-ARG          0827280 
                        MOVE VP-COD-MON-DUAL  TO WS-VARMSG-TXT          0827280 
                                                                        0827290 
                        PERFORM 6100-OBTENER-MENSAJE                    0827300 
                        MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG         0827310 
                                             WS-MENSAJE-TXT-EVE         0827320 
                        PERFORM 5700-GRABAR-LOG-EVENTOS                 14470800
                        PERFORM 6000-FINAL                              14470900
                     END-IF                                             14471000
      *                                                                 14480000
                  WHEN WS-CT-1001                                       14490000
                     IF TI-TRR2-TRANS-CURREN-CODE NOT = WS-CT-840       14500000
      *                 OBTENER MENSAJE PARA CCE                        14581000
                        MOVE WS-CT-05      TO TI-CF06-RESPONSE-CODE-CCE 14586000
                                              WS-TEMP-XX                14587000
                        MOVE WS-CT-AC11    TO TI-CF06-COD-RESP-AMPLIADO 14589000
                                              WS-TEMP-XXXX              14589200
                        MOVE WS-CT-001     TO TI-CF06-ORIGEN-RESPUESTA  14589300
                                                                        14589800
      *                 OBTENER MENSAJE INTERNO                         14589900
                                                                        14590500
                                                                        14590600
                        PERFORM 5600-ACTUALIZA-COMAREA                  14590700
                        MOVE SPACES           TO TI-CA15-I-O-MENSAJES   0827190 
                        SET  TI-CA15-I-RC-APP-TTIB  TO TRUE             0827200 
                        MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT 0827210 
                                                 WS-CODMSG-ESTRUCTURA   0827220 
                                                 WS-COD-ERROR-07        0827230 
                        MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM         0827240 
                                                 WS-PROGRAM             0827250 
                        MOVE TI-CW04-SRV-VP28 TO WS-VARMSG-RSO          0016002 
                        MOVE RG-CA10-O-RCODE  TO WS-VARMSG-ARG          0827280 
                        MOVE VP-COD-MON-DUAL  TO WS-VARMSG-TXT          0827280 
                                                                        0827290 
                        PERFORM 6100-OBTENER-MENSAJE                    0827300 
                        MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG         0827310 
                                             WS-MENSAJE-TXT-EVE         0827320 
                        PERFORM 5700-GRABAR-LOG-EVENTOS                 14590800
                        PERFORM 6000-FINAL                              14590900
                     END-IF                                             14591000
      *                                                                 14600000
                  WHEN OTHER                                            14610000
      *              OBTENER MENSAJE PARA CCE                           14691000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 14696000
                                              WS-TEMP-XX                14697000
                     MOVE WS-CT-AC11       TO TI-CF06-COD-RESP-AMPLIADO 14699000
                                              WS-TEMP-XXXX              14699200
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  14699300
                                                                        14699800
      *              OBTENER MENSAJE INTERNO                            14699900
                                                                        14700500
                                                                        14700600
                     PERFORM 5600-ACTUALIZA-COMAREA                     14700700
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES      0827190 
                     SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                0827200 
                     MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT    0827210 
                                              WS-CODMSG-ESTRUCTURA      0827220 
                                              WS-COD-ERROR-07           0827230 
                     MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM            0827240 
                                              WS-PROGRAM                0827250 
                     MOVE TI-CW04-SRV-VP28 TO WS-VARMSG-RSO             0016002 
                     MOVE RG-CA10-O-RCODE  TO WS-VARMSG-ARG             0827280 
                     MOVE VP-COD-MON-DUAL  TO WS-VARMSG-TXT             0827280 
                                                                        0827290 
                     PERFORM 6100-OBTENER-MENSAJE                       0827300 
                     MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG            0827310 
                                          WS-MENSAJE-TXT-EVE            0827320 
                     PERFORM 5700-GRABAR-LOG-EVENTOS                    14700800
                     PERFORM 6000-FINAL                                 14700900
                  END-EVALUATE                                          14701000
               END-IF                                                   14710000
      *GNS-F                                                                    
      *TA000188957-I                                                            
           ELSE                                                         15320000
      *        OBTENER MENSAJE PARA CCE                                 15401000
               SET  TI-CF06-88-RECH        TO TRUE                      15405000
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     15406000
                                          WS-TEMP-XX                    15407000
               MOVE WS-CT-AC01         TO TI-CF06-COD-RESP-AMPLIADO     15409000
                                          WS-TEMP-XXXX                  15409200
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      15409300
                                                                        15409700
      *        OBTENER MENSAJE INTERNO                                  15409800
               PERFORM 5600-ACTUALIZA-COMAREA                           15410500
               MOVE SPACES           TO TI-CA15-I-O-MENSAJES            0827190 
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      0827200 
               MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT          0827210 
                                        WS-CODMSG-ESTRUCTURA            0827220 
                                        WS-COD-ERROR-07                 0827230 
               MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM                  0827240 
                                        WS-PROGRAM                      0827250 
               MOVE TI-CW04-SRV-VP28 TO WS-VARMSG-RSO                   0016002 
               MOVE RG-CA10-O-RCODE  TO WS-VARMSG-ARG                   0827280 
               MOVE RG-CA10-O-RC-MSG (21:)                              0827280 
                                     TO WS-VARMSG-TXT                   0827280 
                                                                        0827290 
               PERFORM 6100-OBTENER-MENSAJE                             0827300 
               MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG                  0827310 
                                        WS-MENSAJE-TXT-EVE              0827320 
               PERFORM 5700-GRABAR-LOG-EVENTOS                                  
               PERFORM 6000-FINAL                                       15410700
           END-IF                                                       15411000
      *TA000188957-F                                                            
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
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14129500
      *                                                                 14129600
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14129700
      *        SET  TI-CF06-88-RECH        TO TRUE                      14129800
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14129900
                                              WS-TEMP-XX                14130000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)14130100
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14130200
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)14130300
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               14130400
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              14130400
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14130500
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             14130600
      *                                                                 14130700
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14130800
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14132600
      *GNS-F                                                                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14132700
               PERFORM 6000-FINAL                                       14132800
           END-IF                                                       14132900
           .                                                            14133000
      ************************ FIN DE 4190-RUT-LINK-GRAL                14133100
      *************************                                         14134000
       4100-EXTRAE-VALOR-PARAM.                                         14140000
      *************************                                         14150000
      *GNS-I                                                                    
           SET  TI-CA80-88-MPARAMETROS         TO TRUE                  16981400
           MOVE TI-CF01-REG-PARAMETROS         TO TI-CA80-I-REG-MPARAM  16981500
           SET  TI-CA80-I-88-TACC-CONSULTAR    TO TRUE                  16981600
           SET  TI-CA80-I-TCONS-SIMPLE         TO TRUE                  16981700
      *GNS-F                                                                    
                                                                        14160000
      *GNS-I                                                                    
      *    EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              14310000
      *                      INTO(TI-CF01-REG-PARAMETROS)               14311000
      *                    LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)     14312000
      *                    RIDFLD(TI-CF01-KEY03)                        14313000
      *                 KEYLENGTH(LENGTH OF TI-CF01-KEY03)              14313100
      *                      RESP(WS-RESP)                              14313200
      *    END-EXEC                                                     14313300
           EXEC CICS LINK PROGRAM (TI-CW04-PGM-PARAMETROS)              16981900
                          COMMAREA(TI-CA80-COMMAREA)                    16982000
                          LENGTH  (LENGTH OF TI-CA80-COMMAREA)          16982100
                          RESP (WS-RESP)                                16982200
           END-EXEC                                                     16982300
      *GNS-F                                                                    
                                                                        14313400
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        14313500
               MOVE WS-RESP                TO WS-RESP-TXT               14313600
      *        OBTENER MENSAJE PARA CCE                                 14313700
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14313800
      *                                                                 14313900
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14314000
      *        SET  TI-CF06-88-RECH        TO TRUE                      14314100
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14314200
                                              WS-TEMP-XX                14314300
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)14314400
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14314500
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)14314600
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               14314700
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              14314700
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14314800
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             14314900
      *                                                                 14315000
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14315100
      *GNS-F                                                                    
               PERFORM 5600-ACTUALIZA-COMAREA                           14315200
                                                                        14315300
      *        OBTENER MENSAJE INTERNO                                  14315400
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14315500
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      14315600
      *GNS-I                                                                    
      *        MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    14315700
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    16300200
      *GNS-F                                                                    
                                              WS-CODMSG-ESTRUCTURA      14315800
                                              WS-COD-ERROR-07           14315900
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            14316000
                                              WS-PROGRAM                14316100
      *GNS-I                                                                    
      *        MOVE TI-CW03-FILE-PARAMETROS                             14316200
      *                                    TO WS-VARMSG-RSO             14316300
      *        MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             14316400
               MOVE 'LINK'                 TO WS-VARMSG-FUN             16988600
               MOVE TI-CW04-PGM-PARAMETROS TO WS-VARMSG-RSO             16988700
      *GNS-F                                                                    
                                                                        14316500
               PERFORM 6100-OBTENER-MENSAJE                             14316600
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            14316700
                                              WS-MENSAJE-TXT-EVE        14316800
                                                                        14316900
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14317000
      *GNS-F                                                                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14317100
               PERFORM 6000-FINAL                                       14317200
           ELSE                                                         14317300
      *GNS-I                                                                    
      *        CONTINUE                                                 14317400
             IF TI-CA80-O-RC-NRO EQUAL ZEROS                            16982700
               MOVE TI-CA80-O-REG-PARAM(1)     TO TI-CF01-REG-PARAMETROS16990100
             ELSE                                                       16982700
      *        OBTENER MENSAJE PARA CCE                                 16983100
               MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE         16983600
                                      WS-TEMP-XX                        16983700
               MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO         16983900
                                      WS-TEMP-XXXX                      16984100
               MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA          16984200
                                                                        16984600
      *        OBTENER MENSAJE INTERNO                                  16984700
                                                                        16985500
               PERFORM 5600-ACTUALIZA-COMAREA                           16985600
               MOVE SPACES             TO TI-CA15-I-O-MENSAJES                  
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                              
               MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT                
                                          WS-CODMSG-ESTRUCTURA                  
                                          WS-COD-ERROR-07                       
               MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM                        
                                          WS-PROGRAM                            
               MOVE TI-CW04-PGM-PARAMETROS                                      
                                       TO WS-VARMSG-RSO                         
               MOVE TI-CA80-O-RCODE    TO WS-VARMSG-ARG                         
               STRING                                                           
                   TI-CF01-REG-PARAMETROS(1:30) SPACE DELIMITED BY '   '        
                   TI-CA80-O-RC-MSG             SPACE DELIMITED BY '   '        
                                     INTO WS-VARMSG-TXT                         
               END-STRING                                                       
                                                                                
               PERFORM 6100-OBTENER-MENSAJE                                     
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG                    
                                              WS-MENSAJE-TXT-EVE                
                                                                        14560700
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14560900
               PERFORM 6000-FINAL                                       16985800
             END-IF                                                     16985900
      *GNS-F                                                                    
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
      *GNS-I                                                                    
           SET  TI-CA80-88-MPARAMETROS         TO TRUE                  16981400
           MOVE TI-CF01-REG-PARAMETROS         TO TI-CA80-I-REG-MPARAM  16981500
           SET  TI-CA80-I-88-TACC-CONSULTAR    TO TRUE                  16981600
           SET  TI-CA80-I-TCONS-SIMPLE         TO TRUE                  16981700
      *GNS-F                                                                    
      *                                                                 14380000
      *GNS-I                                                                    
      *    EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              14390000
      *         INTO(TI-CF01-REG-PARAMETROS)                            14400000
      *         LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)                14410000
      *         RIDFLD(TI-CF01-KEY03)                                   14420000
      *         KEYLENGTH(LENGTH OF TI-CF01-KEY03)                      14430000
      *         RESP(WS-RESP)                                           14440000
      *    END-EXEC                                                     14450000
           EXEC CICS LINK PROGRAM (TI-CW04-PGM-PARAMETROS)              16981900
                          COMMAREA(TI-CA80-COMMAREA)                    16982000
                          LENGTH  (LENGTH OF TI-CA80-COMMAREA)          16982100
                          RESP (WS-RESP)                                16982200
           END-EXEC                                                     16982300
      *GNS-F                                                                    
                                                                        14460000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        14470000
               MOVE WS-RESP                TO WS-RESP-TXT               14480000
      *        OBTENER MENSAJE PARA CCE                                 14490000
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14500000
      *                                                                 14510000
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      14520000
      *        SET  TI-CF06-88-RECH        TO TRUE                      14530000
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 14540000
                                              WS-TEMP-XX                14550000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)14551000
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 14552000
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)14553000
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               14554000
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              14554000
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  14555000
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             14556000
      *                                                                 14557000
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 14558000
      *GNS-F                                                                    
               PERFORM 5600-ACTUALIZA-COMAREA                           14559000
                                                                        14559100
      *        OBTENER MENSAJE INTERNO                                  14559200
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      14559300
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      14559400
      *GNS-I                                                                    
      *        MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    14559500
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    16300200
      *GNS-F                                                                    
                                              WS-CODMSG-ESTRUCTURA      14559600
                                              WS-COD-ERROR-07           14559700
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            14559800
                                              WS-PROGRAM                14559900
      *GNS-I                                                                    
      *        MOVE TI-CW03-FILE-PARAMETROS                             14560000
      *                                    TO WS-VARMSG-RSO             14560100
      *        MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             14560200
               MOVE 'LINK'                 TO WS-VARMSG-FUN             16988600
               MOVE TI-CW04-PGM-PARAMETROS TO WS-VARMSG-RSO             16988700
      *GNS-F                                                                    
                                                                        14560300
               PERFORM 6100-OBTENER-MENSAJE                             14560400
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            14560500
                                              WS-MENSAJE-TXT-EVE        14560600
                                                                        14560700
      *GNS-I                                                                    
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     14560800
      *GNS-F                                                                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14560900
               PERFORM 6000-FINAL                                       14561000
           ELSE                                                         14561100
      *GNS-I                                                                    
             IF TI-CA80-O-RC-NRO EQUAL ZEROS                            16982700
               MOVE TI-CA80-O-REG-PARAM(1)     TO TI-CF01-REG-PARAMETROS16990100
      *GNS-F                                                                    
               MOVE TI-CF01-DTBL-VALOR(1:1)    TO WS-TIPO-DOC-ORD-HOMOL 14561200
      *GNS-I                                                                    
             ELSE                                                       16982700
      *        OBTENER MENSAJE PARA CCE                                 16983100
               MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE         16983600
                                      WS-TEMP-XX                        16983700
               MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO         16983900
                                      WS-TEMP-XXXX                      16984100
               MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA          16984200
                                                                        16984600
      *        OBTENER MENSAJE INTERNO                                  16984700
                                                                        16985500
               PERFORM 5600-ACTUALIZA-COMAREA                           16985600
               MOVE SPACES             TO TI-CA15-I-O-MENSAJES                  
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                              
               MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT                
                                          WS-CODMSG-ESTRUCTURA                  
                                          WS-COD-ERROR-07                       
               MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM                        
                                          WS-PROGRAM                            
               MOVE TI-CW04-PGM-PARAMETROS                                      
                                       TO WS-VARMSG-RSO                         
               MOVE TI-CA80-O-RCODE    TO WS-VARMSG-ARG                         
               STRING                                                           
                   TI-CF01-REG-PARAMETROS(1:30) SPACE DELIMITED BY '   '        
                   TI-CA80-O-RC-MSG             SPACE DELIMITED BY '   '        
                                     INTO WS-VARMSG-TXT                         
               END-STRING                                                       
                                                                                
               PERFORM 6100-OBTENER-MENSAJE                                     
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG                    
                                              WS-MENSAJE-TXT-EVE                
                                                                        14560700
               PERFORM 5700-GRABAR-LOG-EVENTOS                          14560900
               PERFORM 6000-FINAL                                       16985800
             END-IF                                                     16985900
      *GNS-F                                                                    
           END-IF                                                       14561300
           .                                                            14561400
      ************************ FIN DE 4155-HOMOLOGA-DOC                 14561500
      *GNS-I                                                                    
      ***********************                                           16331000
       4156-HOMOLOGA-DOC-BEN.                                           16340000
      ***********************                                           16350000
           MOVE SPACES                     TO TI-CF01-KEY03             16360000
           MOVE WS-CT-03                   TO TI-CF01-KEY03-TIP-PRM     16370000
           MOVE WS-CT-07C                  TO TI-CF01-KEY03-CTABL       16380000
           MOVE WS-TIPO-DOC-BEN-HOMOL      TO TI-CF01-KEY03-DTABL       16391000
      *                                                                 16400000
           SET  TI-CA80-88-MPARAMETROS         TO TRUE                  16981400
           MOVE TI-CF01-REG-PARAMETROS         TO TI-CA80-I-REG-MPARAM  16981500
           SET  TI-CA80-I-88-TACC-CONSULTAR    TO TRUE                  16981600
           SET  TI-CA80-I-TCONS-SIMPLE         TO TRUE                  16981700
      *                                                                 16400000
           EXEC CICS LINK PROGRAM (TI-CW04-PGM-PARAMETROS)              16981900
                          COMMAREA(TI-CA80-COMMAREA)                    16982000
                          LENGTH  (LENGTH OF TI-CA80-COMMAREA)          16982100
                          RESP (WS-RESP)                                16982200
           END-EXEC                                                     16982300
                                                                        16480000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        16490000
               MOVE WS-RESP                TO WS-RESP-TXT               16500000
      *        OBTENER MENSAJE PARA CCE                                 16551000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 16556000
                                              WS-TEMP-XX                16557000
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 16559000
                                              WS-TEMP-XXXX              16559200
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  16559300
               PERFORM 5600-ACTUALIZA-COMAREA                           16559700
                                                                        16559800
      *        OBTENER MENSAJE INTERNO                                  16559900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16560000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      16560100
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    16560200
                                              WS-CODMSG-ESTRUCTURA      16560300
                                              WS-COD-ERROR-07           16560400
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            16560500
                                              WS-PROGRAM                16560600
               MOVE 'LINK'                 TO WS-VARMSG-FUN             16988600
               MOVE TI-CW04-PGM-PARAMETROS TO WS-VARMSG-RSO             16988700
                                                                        16561000
               PERFORM 6100-OBTENER-MENSAJE                             16561100
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            16561200
                                              WS-MENSAJE-TXT-EVE        16561300
                                                                        16561400
               PERFORM 5700-GRABAR-LOG-EVENTOS                          16561500
               PERFORM 6000-FINAL                                       16561600
           ELSE                                                         16562000
             IF TI-CA80-O-RC-NRO EQUAL ZEROS                            16982700
               MOVE TI-CA80-O-REG-PARAM(1)     TO TI-CF01-REG-PARAMETROS16990100
               MOVE TI-CF01-DTBL-VALOR(1:1)    TO WS-TIPO-DOC-BEN-HOMOL 16570000
             ELSE                                                       16982700
      *        OBTENER MENSAJE PARA CCE                                 16983100
               MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE         16983600
                                      WS-TEMP-XX                        16983700
               MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO         16983900
                                      WS-TEMP-XXXX                      16984100
               MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA          16984200
                                                                        16984600
      *        OBTENER MENSAJE INTERNO                                  16984700
                                                                        16985500
               PERFORM 5600-ACTUALIZA-COMAREA                           16985600
               MOVE SPACES             TO TI-CA15-I-O-MENSAJES                  
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                              
               MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT                
                                          WS-CODMSG-ESTRUCTURA                  
                                          WS-COD-ERROR-07                       
               MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM                        
                                          WS-PROGRAM                            
               MOVE TI-CW04-PGM-PARAMETROS                                      
                                       TO WS-VARMSG-RSO                         
               MOVE TI-CA80-O-RCODE    TO WS-VARMSG-ARG                         
      *TA000188957-I                                                            
      *        MOVE TI-CA80-O-RC-MSG   TO WS-VARMSG-TXT                         
               STRING                                                           
                    TI-CF01-REG-PARAMETROS(1:30)                                
                    SPACE                                                       
                        DELIMITED BY '   '                                      
                    TI-CA80-O-RC-MSG                                            
                    SPACE                                                       
                        DELIMITED BY '   '                                      
                                     INTO WS-VARMSG-TXT                         
               END-STRING                                                       
      *TA000188957-F                                                            
                                                                                
               PERFORM 6100-OBTENER-MENSAJE                                     
               MOVE WS-MENSAJE-TXT     TO TI-CF06-TXTMSG                        
                                          WS-MENSAJE-TXT-EVE                    
               PERFORM 5700-GRABAR-LOG-EVENTOS                          16985700
               PERFORM 6000-FINAL                                       16985800
             END-IF                                                     16985900
           END-IF                                                       16580000
           .                                                            16580100
      ************************ FIN DE 4156-HOMOLOGA-DOC-BEN             16581000
      *GNS-F                                                                    
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
           MOVE WS-CT-S                TO RG-CA10-I-FLAG-GREM-94        14670000
           MOVE WS-CT-S                TO RG-CA10-I-FLAG-CTA-ESP        14680000
           MOVE SPACES                 TO RG-CA10-I-NRO-OPE-CANAL       14690000
           MOVE ZEROS                  TO WS-NRO-OPERACION              14691000
      *GNS-I                                                                    
      *    MOVE TI-TR02-AUTORIZAT-ID-RESP                               14692000
           MOVE TI-CAR2-AUTORIZAT-ID-RESP                               14692000
      *GNS-F                                                                    
                                       TO WS-NRO-OPERACION(3:6)         14692100
           MOVE WS-NRO-OPERACION       TO RG-CA10-I-NRO-OPE-CANAL       14693000
           MOVE WS-CT-01               TO RG-CA10-I-VERSION             14720000
           MOVE WS-CT-0                TO RG-CA10-I-FLAG-EXT-OPE        14730000
           MOVE ZEROS                  TO RG-CA10-I-NRO-OPE-CANAL-A-EXT 14740000
           MOVE SPACES                 TO RG-CA10-I-TERMINAL-CANAL      14750000
           MOVE SPACES                 TO RG-CA10-I-TERMINAL-CANAL      14760000
                                                                                
      *ENVIO TETIS Y USUARIO SEGUN CONDICION PASAN POR BCTITPR8         TA193512
      *BCTITPRA-TRANSFERENCIA EN LINEA                                  TA193512
           IF TI-TRR2-88-TIP-PROC-LINEA                                 TA193512
              IF TI-TRR2-88-SI-REENV                                    TA193512
                 MOVE WS-IR0997        TO RG-CA10-I-K-USR-CODIGO        TA193512
                 MOVE WS-IRZ7          TO RG-CA10-I-TERM-CICS-TETI      TA193512
              ELSE                                                      TA193512
      *QTI3    -CONFIRMACION DE ABONO EN LINEA                          TA193512
                 MOVE ALL SPACES       TO RG-CA10-I-K-USR-CODIGO        TA193512
                                          RG-CA10-I-TERM-CICS-TETI      TA193512
              END-IF                                                    TA193512
           ELSE                                                         TA193512
      *BCTITPL1-REGULARIZACION PDTES RECEPTOR - BATCH                   TA193512
              MOVE WS-IR0999           TO RG-CA10-I-K-USR-CODIGO        TA193512
              MOVE WS-IRZ9             TO RG-CA10-I-TERM-CICS-TETI      TA193512
           END-IF                                                       TA193512
                                                                                
                                                                                
           MOVE 'BUKCTA01'             TO RG-CA10-I-KEY-MACRO-OPE       14780000
           MOVE SPACES                 TO RG-CA10-I-K-USR-CODIGO-SUP    14790000
           MOVE 0                      TO RG-CA10-I-FLAG-AUTORIZACION   14800000
           MOVE 0                      TO RG-CA10-I-FLAG-MODO-ENTRADA   14810000
           MOVE '0'                    TO RG-CA10-I-FLAG-NEXT-DAY       14820000
           MOVE WS-HORA-INI            TO RG-CA10-I-HORA-CANAL          14830000
           MOVE WS-FECHA-INI           TO RG-CA10-I-FECHA-CANAL         14840000
           MOVE 0                      TO RG-CA10-I-FLAG-STR-FWRD       14850000
      *GNS-I                                                                    
      *    MOVE TI-CW03-SUCAGE-SUC(1)  TO RG-CA10-I-SUCURSAL-OPERACION  14860000
      *    MOVE TI-CW03-SUCAGE-AGE(1)  TO RG-CA10-I-AGENCIA-OPERACION   14870000
           MOVE TI-CW04-SUCAGE-SUC(1)  TO RG-CA10-I-SUCURSAL-OPERACION  14860000
           MOVE TI-CW04-SUCAGE-AGE(1)  TO RG-CA10-I-AGENCIA-OPERACION   14870000
      *GNS-F                                                                    
           MOVE SPACES                 TO RG-CA10-I-FLAG-CONSUMO-SRV    14880000
           MOVE WS-CT-2                TO RG-CA10-I-VERSION-HEADER      14890000
                                                                        14891000
      *TA000188957-I                                                            
      *    PERFORM 5200-ASIGNAR-TERM-USER                               14892000
      *    MOVE RG-CA04-I-HDR-STD-IN   TO RG-CA10-I-INPUT-CANAL-HEADER  14893000
      *TA000188957-F                                                            
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
      *GNS-I                                                                    
      *    IF TI-TR02-INDI-MISMO-CLIENTE = WS-CT-M                      15000000
           IF TI-TRR2-INDI-MISMO-CLIENTE = WS-CT-M                      15000000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-IMPORTE(1:10)TO WS-SOLES(5:10)                  15640000
           MOVE TI-TRR2-IMPORTE(1:10)TO WS-SOLES(5:10)                  15640000
      *GNS-F                                                                    
           MOVE '.'               TO WS-PUNTO                           15650000
      *GNS-I                                                                    
      *    MOVE TI-TR02-IMPORTE(11:2) TO WS-CENTI(1:2)                  15660000
           MOVE TI-TRR2-IMPORTE(11:2) TO WS-CENTI(1:2)                  15660000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      15681300
      *                                                                 15681400
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      15681500
      *        SET  TI-CF06-88-RECH        TO TRUE                      15681600
      *GNS-F                                                                    
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     15681700
                                          WS-TEMP-XX                    15681800
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(1: 2)    15681900
      *                                   TI-TR02-RESPONSE-CODE-CCE             
      *GNS-F                                                                    
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     15682000
      *GNS-I                                                                    
      *                                   WS-CODMSG-ESTRUCTURA(3: 4)    15682100
      *        MOVE WS-CT-1021         TO WS-CT-NUMER                   15682200
      *                                   TI-TR02-COD-RESP-AMPLIADO             
                                          WS-TEMP-XXXX                  15682200
      *GNS-F                                                                    
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      15682300
      *GNS-I                                                                    
      *                                   TI-TR02-ORIGEN-RESPUESTA              
      *        PERFORM 6100-OBTENER-MENSAJE                             15682400
      *                                                                 15682500
      *        MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     15682600
      *GNS-F                                                                    
                                                                        15682700
      *        OBTENER MENSAJE INTERNO                                  15682800
      *GNS-I                                                                    
      *        MOVE RG-CA04-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT        15682900
      *                                   WS-COD-ERROR-07               15683000
      *        MOVE WS-RTN-ASIGNA-TETI TO TI-CF06-PRGNOM                15683100
      *                                   WS-PROGRAM                    15683200
      *        MOVE RG-CA04-O-MSG      TO TI-CF06-TXTMSG                15683300
      *                                   WS-MENSAJE-TXT-EVE            15683400
      *                                                                 15683500
      *        PERFORM 5500-ACTUALIZA-MASTER-TRANSF                     15683600
      *GNS-F                                                                    
               PERFORM 5600-ACTUALIZA-COMAREA                           15683700
      *GNS-I                                                                    
               MOVE SPACES             TO TI-CA15-I-O-MENSAJES           0827190
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       0827200
               MOVE 'TI0412'           TO TI-CF06-CODMSG-ESTRUCT         0827210
                                          WS-CODMSG-ESTRUCTURA           0827220
                                          WS-COD-ERROR-07                0827230
               MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM                 0827240
                                          WS-PROGRAM                     0827250
               MOVE WS-RTN-ASIGNA-TETI TO WS-VARMSG-RSO                  0016002
               MOVE RG-CA04-O-RCODE    TO WS-VARMSG-ARG                  0827280
               MOVE RG-CA04-O-MSG      TO WS-VARMSG-TXT                  0827280
                                                                         0827290
               PERFORM 6100-OBTENER-MENSAJE                              0827300
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             0827310
                                              WS-MENSAJE-TXT-EVE         0827320
      *GNS-F                                                                    
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
      *GNS-I                                                                    
               MOVE WS-RESP                TO WS-RESP-TXT                       
      *GNS-F                                                                    
      *GNS-I                                                                    
      *        MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      15687000
      *                                                                 15687100
      *        SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      15687200
      *        SET  TI-CF06-88-RECH        TO TRUE                      15687300
      *GNS-F                                                                    
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 15687400
                                              WS-TEMP-XX                15687500
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(1: 2)15687600
      *                                       TI-TR02-RESPONSE-CODE-CCE         
      *GNS-F                                                                    
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 15687700
      *GNS-I                                                                    
      *                                       WS-CODMSG-ESTRUCTURA(3: 4)15687800
      *        MOVE WS-CT-1021             TO WS-CT-NUMER               15687900
      *                                       TI-TR02-COD-RESP-AMPLIADO         
                                              WS-TEMP-XXXX              15687900
      *GNS-F                                                                    
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  15688000
      *GNS-I                                                                    
      *                                       TI-TR02-ORIGEN-RESPUESTA          
      *        PERFORM 6100-OBTENER-MENSAJE                             15688100
      *                                                                 15688200
      *        MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 15688300
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *******************************                                   15684300
       5550-BORRA-ARCHIVO-REINTENTOS.                                   15684400
      *******************************                                   15684500
      ******************************************************************15684600
      * BORRAR DE ARCHIVO DE REINTENTOS                                *15684700
      ******************************************************************15684800
           INITIALIZE  TI-CSEP-REG-TRANS                                15692600
                       REPLACING  ALPHANUMERIC DATA BY SPACES           15692700
                                  NUMERIC DATA BY ZEROS                 15692800
      *                                                                 15692900
           SET  TI-CSEP-88-COD-PROCESO-TRN TO TRUE                      15693000
           SET  TI-CSEP-88-TIPO-ROL-RECEPT TO TRUE                      15693100
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CSEP-TRACE-ADQUIRIENTE 07690000
           MOVE TI-TRR2-CANAL              TO TI-CSEP-CANAL-CCE         07700000
NO HAY     MOVE SPACES                     TO TI-CSEP-BIN-ADQUIRIENTE   07710000
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CSEP-TERMINAL-ID       07720000
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          06160000
           MOVE WS-DATE-LOCAL              TO TI-CSEP-FECHA-TRANS       06160000
           MOVE TI-TRR2-CREATION-TIME      TO TI-CSEP-HORA-TRANS        06170000
      *                                                                 15694300
                                                                        15684900
           EXEC CICS DELETE  FILE (TI-CW04-FILE-REINTENTOS-RE)          00160022
                           RIDFLD (TI-CSEP-REG-KEY-PEND)                12010000
                        KEYLENGTH (LENGTH OF TI-CSEP-REG-KEY-PEND)      12020000
                             RESP (WS-RESP)                             12030000
                            RESP2 (WS-RESP2)                                    
           END-EXEC                                                     12040000
                                                                        15685500
           EVALUATE WS-RESP                                             15685600
             WHEN DFHRESP(NORMAL)                                       15685700
               CONTINUE                                                 15685800
             WHEN OTHER                                                 15685900
               MOVE WS-RESP                TO WS-RESP-TXT                       
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 15687400
                                              WS-TEMP-XX                15687500
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 15687700
                                              WS-TEMP-XXXX              15687900
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  15688000
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
               MOVE TI-CW04-FILE-REINTENTOS-RE                          00160022
                                           TO WS-VARMSG-RSO             00160022
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
      ************************ FIN DE 5550-GRABA-ARCHIVO-REINTENTOS     15690600
      *GNS-F                                                                    
      ************************                                          15690700
       5600-ACTUALIZA-COMAREA.                                          15690800
      ************************                                          15690900
      ******************************************************************15691000
      *ACTUALIZA COMMAREA CON CAMPO ERRADO                              15691100
      ******************************************************************15691200
      *GNS-I                                                                    
      *    MOVE WS-TEMP-XX             TO TI-TR02-RESPONSE-CODE-CCE     15691300
      *    MOVE WS-CT-NUMER            TO TI-TR02-COD-RESP-AMPLIADO     15691400
      *    MOVE WS-CT-001              TO TI-TR02-ORIGEN-RESPUESTA      15691500
      *    MOVE WS-MENSAJE-TXT         TO TI-TR02-MENSAJE-RESPUESTA     15691600
      **   MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     00160022
      *    MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
      *    MOVE TI-CA02-AREA-COMUNICACION                               00160022
      *                                TO DFHCOMMAREA                   00160022
           MOVE WS-TEMP-XX             TO TI-TRR2-RESPONSE-CODE-CCE     07530000
           MOVE WS-TEMP-XXXX           TO TI-TRR2-COD-RESP-AMPLIADO     07531000
           MOVE TI-TRR2-I-TRAMA        TO TI-CAR2-REG-TRANS-DATA        00160022
           MOVE TI-CAR2-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 15693300
      *    MOVE TI-TR02-CANAL              TO TI-CF07-CANAL-CCE         15693400
      *    MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF07-BIN-ADQUIRIENTE   15693500
      *    MOVE TI-TR02-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       15693600
      *    MOVE TI-TR02-DATE-LOCAL         TO TI-CF07-FECHA-TRANS       15693700
      *    MOVE TI-TR02-TIME-LOCAL         TO TI-CF07-HORA-TRANS        15693800
           MOVE TI-TRR2-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 07690000
           MOVE TI-TRR2-CANAL              TO TI-CF07-CANAL-CCE         07700000
NO HAY     MOVE SPACES                     TO TI-CF07-BIN-ADQUIRIENTE   07710000
           MOVE TI-TRR2-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       07720000
           MOVE TI-TRR2-CREATION-DATE      TO WS-CREATION-DATE          06160000
           MOVE WS-DATE-LOCAL              TO TI-CF07-FECHA-TRANS       06160000
           MOVE TI-TRR2-CREATION-TIME      TO TI-CF07-HORA-TRANS        06170000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
                    MOVE WS-RESP                     TO WS-RESP-TXT     05800000
                    MOVE WS-COD-E-LOG-EVENTOS        TO WS-CODMSG       05800000
                    MOVE WS-88-ERROR-GRABAR-LOGEVEN  TO WS-TXTMSG       05810000
                    MOVE WS-CODMSG-ESTRUCTURA   TO WS-CSMT-COD-RETORNO  05800000
                    MOVE WS-COD-PROG            TO WS-CSMT-COD-PROGRAMA 05800000
                    STRING                                                      
                        '-'                                                     
                        WS-RESP-TXT(07:02)                                      
                        '-'                                                     
                        WS-FILE-NM-EVEN-LOG                                     
                        '-'                                                     
                        WS-TXTMSG                                               
                        DELIMITED BY SIZE     INTO WS-CSMT-MENSAJE              
                    END-STRING                                                  
                    PERFORM 6400-WRITE-CSMT                             00160022
      *GNS-F                                                                    
                    PERFORM 6000-FINAL                                  15695600
           END-EVALUATE                                                 15695700
           .                                                            15695800
      ************************ FIN DE 5700-GRABAR-LOG-EVENTOS           15695900
      *GNS-I                                                                    
      *************************                                         15696000
       5900-PROCESO-CANCELADAS.                                         07280000
      *************************                                         15696000
           CONTINUE                                                     16481000
           .                                                            15695800
      ************************ FIN DE 5900-PROCESO-CANCELADAS           15695900
      *GNS-F                                                                    
      ************                                                      15696000
       6000-FINAL.                                                      15696100
      ************                                                      15697000
      ******************************************************************15700000
      * FIN DEL PROCESO Y ENVIA MENSAJE AL OPERADOR                    *15710000
      ******************************************************************15711000
                                                                        15730000
      *GNS-I                                                                    
           EXEC CICS                                                            
              UNLOCK FILE (WS-FILE-NM-MAESTRO)                                  
           END-EXEC                                                             
      *GNS-F                                                                    
      *    MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     00160022
      *GNS-I                                                                    
      *    MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
      *    MOVE TI-CA02-AREA-COMUNICACION                               00160022
      *                                TO DFHCOMMAREA                   00160022
           MOVE TI-TRR2-I-TRAMA        TO TI-CAR2-REG-TRANS-DATA        00160022
           MOVE TI-CAR2-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE TI-CW03-PGM-MENSAJES       TO WS-RTN-SGTE               15769700
           MOVE TI-CW04-PGM-MENSAJES       TO WS-RTN-SGTE               15769700
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *        STRING 'BCTITPR3' 'RUTINA' WS-RTN-SGTE                   15771100
               STRING 'BCTITPR9' 'RUTINA' WS-RTN-SGTE                   15771100
      *GNS-F                                                                    
                      'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO 15771200
                      WS-TXTMSG                                         15771300
      *GNS-I                                                                    
               END-STRING                                               15771100
               MOVE WS-COD-E-LINK-GRAL         TO WS-CODMSG             05800000
               MOVE WS-CODMSG-ESTRUCTURA       TO WS-CSMT-COD-RETORNO   05800000
               MOVE WS-COD-PROG                TO WS-CSMT-COD-PROGRAMA  05800000
               MOVE WS-TXTMSG                  TO WS-CSMT-MENSAJE       05800000
               PERFORM 6400-WRITE-CSMT                                  00160022
               PERFORM 6000-FINAL                                       12342200
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE DGC-NUM-ICLI (IND)  TO  WS-NROCLI-CONSIS-WORK           15880000
           MOVE DGC-NUM-ICLI (TIT)  TO  WS-NROCLI-CONSIS-WORK           15880000
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    MOVE WS-NROCLI-CONSIS-WORK1 TO DGC-NUM-ICLI (IND)            16020000
           MOVE WS-NROCLI-CONSIS-WORK1 TO DGC-NUM-ICLI (TIT)            16020000
      *GNS-F                                                                    
           .                                                            16020100
      ************************ FIN DE 3750-VALIDA-CARACTERES            16021000
      *GNS-I                                                                    
      ******************************                                    16400000
       5000-VALIDA-CCI-BENEFICIARIO.                                    07790700
      ******************************                                    16400000
      *                                                                 08900000
           EVALUATE TI-TRR2-CCI-CLI-BENEFICIA(7:1)                      08910000
               WHEN WS-CT-0                                             08920000
                   PERFORM 5100-CUENTA-IMPACS                           08930000
      *                                                                 08940000
               WHEN WS-CT-1                                             08950000
                   PERFORM 5200-CUENTA-SAVING                           08960000
      *                                                                 08970000
               WHEN OTHER                                               08980000
      *            OBTENER MENSAJE PARA CCE                             09061000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 09066000
                                              WS-TEMP-XX                09067000
                   MOVE WS-CT-AC14         TO TI-CF06-COD-RESP-AMPLIADO 09069000
                                              WS-TEMP-XXXX              09069200
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  09069300
                                                                        09069700
      *            OBTENER MENSAJE INTERNO                              09069800
                                                                        09070500
                   PERFORM 5600-ACTUALIZA-COMAREA                       09070600
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0403'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
                   MOVE WS-CT-TIPO-CUENTA      TO WS-VARMSG-RSO         00160022
                   MOVE TI-TRR2-CCI-CLI-BENEFICIA(7:1)                  08272800
                                               TO WS-VARMSG-ARG         08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
                   PERFORM 5700-GRABAR-LOG-EVENTOS                      09070700
                   PERFORM 6000-FINAL                                   09070800
           END-EVALUATE                                                 09071000
           .                                                            09080000
      ************************ FIN DE 5000-VALIDA-CCI-BENEFICIARIO      16590000
      ********************                                              10610000
       5100-CUENTA-IMPACS.                                              10620000
      ********************                                              10630000
                                                                        10640000
           MOVE 'IMDS'                 TO CA-IM-COD-TRN-I               10670000
           MOVE WS-CT-1                TO CA-IM-COD-INST-I              10680000
           STRING  'APTI' RG-CA05-O-0A-AMBIENTE                         10690000
                DELIMITED BY SIZE INTO CA-IM-COD-CANAL-I                10700000
           END-STRING                                                   10710000
           MOVE SPACES                 TO CA-IM-COD-USU-I               10720000
           MOVE WS-CT-S                TO CA-IM-FLAG-VERIF1-I           10730000
           MOVE WS-CT-S                TO CA-IM-FLAG-VERIF2-I           10740000
           MOVE ZEROS                  TO WS-NRO-OPERACION              10750000
           MOVE TI-CAR2-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     10760000
           MOVE WS-NRO-OPERACION       TO CA-IM-NRO-OPERACION-I         10770000
           MOVE WS-CT-01               TO CA-IM-NRO-VERSION-I           10780000
           MOVE WS-CT-0                TO CA-IM-FLAG-EXTORNO-I          10790000
           MOVE ZEROS                  TO CA-IM-OPE-CANAL-A-EXT-I       10800000
           MOVE SPACES                 TO CA-IM-COD-TERM-CAN-I          10810000
           MOVE SPACES                 TO CA-IM-COD-TERM-CICS-I         10820000
           MOVE SPACES                 TO CA-IM-COD-MACRO-I             10830000
           MOVE SPACES                 TO CA-IM-NUM-VERS-MACRO-I        10840000
           MOVE SPACES                 TO CA-IM-COD-SUP-MACRO-I         10850000
           MOVE SPACES                 TO CA-IM-FLG-AUT-I               10860000
           MOVE SPACES                 TO CA-IM-FLG-REENT-I             10870000
           MOVE SPACES                 TO CA-IM-FLG-NEXTDAY-I           10880000
           MOVE WS-HORA-INI            TO CA-IM-HRA-TRN-I               10890000
           MOVE WS-FECHA-INI           TO CA-IM-FEC-TRN-I               10900000
           MOVE SPACES                 TO CA-IM-FLG-STORE-FWD-I         10910000
           MOVE WS-CT-111              TO CA-IM-SUC-OPE-I               10920000
           MOVE WS-CT-054              TO CA-IM-AGE-OPE-I               10930000
           MOVE SPACES                 TO CA-IM-FLG-CONS-SRV-I          10940000
           MOVE WS-CT-1                TO CA-IM-NUM-VERS-INPUT-I        10950000
                                                                        10950100
           MOVE CA-IM-HEADER-ESTANDAR-I                                 10950200
                                       TO RG-CA10-I-INPUT-CANAL-HEADER  10950300
      *TA000188957-I                                                            
      *    PERFORM 5200-ASIGNAR-TERM-USER                               10951000
      *    MOVE RG-CA04-I-HDR-STD-IN   TO CA-IM-HEADER-ESTANDAR-I       10951100
           MOVE 'IR99'                 TO RG-CA10-I-TERM-CICS-TETI      10951100
           MOVE 'IR0099'               TO RG-CA10-I-K-USR-CODIGO        10951100
           MOVE RG-CA10-I-INPUT-CANAL-HEADER                            10951100
                                       TO CA-IM-HEADER-ESTANDAR-I       10951100
      *TA000188957-F                                                            
                                                                        10952000
           MOVE SPACES           TO CA-IM-COD-CTA-COM-I                 10960000
           MOVE TI-TRR2-CCI-CLI-BENEFICIA(4:3)                          10970000
                                 TO CA-IM-COD-CTA-COM-I(8:3)            10980000
           MOVE TI-TRR2-CCI-CLI-BENEFICIA(9:10)                         10990000
                                 TO CA-IM-COD-CTA-COM-I(11:10)          11000000
           MOVE '0000'           TO CA-IM-COD-PRD-IM-I                  11010000
           MOVE SPACES           TO CA-IM-FLAG-COBCOM-I                 11020000
           MOVE SPACES           TO CA-IM-FLAG-MOV-I                    11030000
           MOVE SPACES           TO CA-IM-FLAG-CHEQ-I                   11040000
           MOVE SPACES           TO CA-IM-FLAG-IMRTE-I                  11050000
           MOVE SPACES           TO CA-IM-FLAG-IMLMT-I                  11060000
      *                                                                 11070000
      *INVOCAR AL PROGRAMAS CICS BCIMTP27 CUENTA IMPACS (CTA.CTE)       11130000
      *                                                                 11140000
           EXEC CICS LINK PROGRAM (TI-CW04-SRV-IMDS)                    11150000
                          COMMAREA(CA-IM-REG-INQ)                       11160000
                          LENGTH  (LENGTH OF CA-IM-REG-INQ)             11170000
                          RESP    (WS-RESP)                             11190000
                          RESP2   (WS-RESP2)                            11200000
           END-EXEC                                                     11210000
      *                                                                 11220000
           EVALUATE WS-RESP                                             11230000
             WHEN NOT DFHRESP(NORMAL)                                   11240000
      *        OBTENER MENSAJE PARA CCE                                 11351000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 11356000
                                              WS-TEMP-XX                11357000
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 11359000
                                              WS-TEMP-XXXX              11359200
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  11359300
               PERFORM 5600-ACTUALIZA-COMAREA                           11359700
                                                                        11359800
      *        OBTENER MENSAJE INTERNO                                  11359900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      11360000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      11360100
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    11360200
                                              WS-CODMSG-ESTRUCTURA      11360300
                                              WS-COD-ERROR-07           11360400
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            11360500
                                              WS-PROGRAM                11360600
               MOVE 'LINK'                 TO WS-VARMSG-FUN             11360700
               MOVE TI-CW04-SRV-IMDS       TO WS-VARMSG-RSO             11360800
                                                                        11360900
               PERFORM 6100-OBTENER-MENSAJE                             11361000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            11361100
                                              WS-MENSAJE-TXT-EVE        11361200
                                                                        11361300
               PERFORM 5700-GRABAR-LOG-EVENTOS                          11361400
               PERFORM 6000-FINAL                                       11361500
             WHEN DFHRESP(NORMAL)                                       11362000
                IF CA-FIN-OK-INQ OF CA-IM-REG-OUT                       11370000
                   IF (WS-CT-00 = CA-IM-STAT-CTA-COD(3:2) OR            11380000
                       WS-CT-02 = CA-IM-STAT-CTA-COD(3:2) OR            11390000
                       WS-CT-06 = CA-IM-STAT-CTA-COD(3:2) OR            11400000
                       WS-CT-07 = CA-IM-STAT-CTA-COD(3:2) OR            11410000
                       WS-CT-09 = CA-IM-STAT-CTA-COD(3:2))              11420000
                       CONTINUE                                         11430000
                   END-IF                                               11440000
      *                                                                 11450000
                   IF (WS-CT-04 = CA-IM-STAT-CTA-COD(3:2) OR            11460000
                       WS-CT-05 = CA-IM-STAT-CTA-COD(3:2) OR            11470000
                       WS-CT-08 = CA-IM-STAT-CTA-COD(3:2))              11480000
      *                OBTENER MENSAJE PARA CCE                         11561000
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 11566000
                                              WS-TEMP-XX                11567000
                       MOVE WS-CT-AC07     TO TI-CF06-COD-RESP-AMPLIADO 11569000
                                              WS-TEMP-XXXX              11569200
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  11569300
                                                                        11569700
      *                OBTENER MENSAJE INTERNO                          11569800
                                                                        11570400
                                                                        11570500
                       PERFORM 5600-ACTUALIZA-COMAREA                   11570600
                       MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200
                       MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210
                                                WS-CODMSG-ESTRUCTURA     0827220
                                                WS-COD-ERROR-07          0827230
                       MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240
                                                WS-PROGRAM               0827250
                       MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002
                       MOVE CA-IM-STAT-CTA-COD(3:2)                      0827280
                                             TO WS-VARMSG-ARG            0827280
                       MOVE CA-IM-STAT-CTA-DES                           0827280
                                             TO WS-VARMSG-TXT            0827280
                                                                         0827290
                       PERFORM 6100-OBTENER-MENSAJE                      0827300
                       MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  11570700
                       PERFORM 6000-FINAL                               11570800
                   END-IF                                               11571000
      *                                                                 11580000
                   IF (WS-CT-01 = CA-IM-STAT-CTA-COD(3:2) OR            11590000
                       WS-CT-03 = CA-IM-STAT-CTA-COD(3:2))              11600000
      *                OBTENER MENSAJE PARA CCE                         11681000
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 11686000
                                              WS-TEMP-XX                11687000
                       MOVE WS-CT-AC06     TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  11689300
                                                                        11689700
      *                OBTENER MENSAJE INTERNO                          11689800
                                                                        11690400
                                                                        11690500
                       PERFORM 5600-ACTUALIZA-COMAREA                   11690600
                       MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190
                       SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200
                       MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210
                                                WS-CODMSG-ESTRUCTURA     0827220
                                                WS-COD-ERROR-07          0827230
                       MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240
                                                WS-PROGRAM               0827250
                       MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002
                       MOVE CA-IM-STAT-CTA-COD(3:2)                      0827280
                                             TO WS-VARMSG-ARG            0827280
                       MOVE CA-IM-STAT-CTA-DES                           0827280
                                             TO WS-VARMSG-TXT            0827280
                                                                         0827290
                       PERFORM 6100-OBTENER-MENSAJE                      0827300
                       MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310
                                                WS-MENSAJE-TXT-EVE       0827320
                       PERFORM 5700-GRABAR-LOG-EVENTOS                  11690700
                       PERFORM 6000-FINAL                               11690800
                   END-IF                                               11691000
                ELSE                                                    11700000
                   EVALUATE TRUE                                        11710000
                   WHEN WS-CT-IM0316 = CA-IM-COD-RET                    11720000
      *               OBTENER MENSAJE PARA CCE                          11801000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 11806000
                                              WS-TEMP-XX                11807000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 11809000
                                              WS-TEMP-XXXX              11809200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  11809300
                                                                        11809700
      *               OBTENER MENSAJE INTERNO                           11809800
                                                                        11810500
                      PERFORM 5600-ACTUALIZA-COMAREA                    11810600
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002 
                      MOVE CA-IM-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-IM-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   11810700
                      PERFORM 6000-FINAL                                11810800
      *                                                                 11820000
                   WHEN WS-CT-IM0304 = CA-IM-COD-RET                    11830000
                   WHEN WS-CT-IM0504 = CA-IM-COD-RET                    11840000
      *               OBTENER MENSAJE PARA CCE                          11841000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 11846000
                                              WS-TEMP-XX                11847000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 11849000
                                              WS-TEMP-XXXX              11849200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  11849300
                                                                        11849700
      *               OBTENER MENSAJE INTERNO                           11849800
                      PERFORM 5600-ACTUALIZA-COMAREA                    11850500
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002 
                      MOVE CA-IM-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-IM-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   11850600
                      PERFORM 6000-FINAL                                11850700
      *                                                                 11940000
                   WHEN WS-CT-IM0604 = CA-IM-COD-RET                    11950000
      *               OBTENER MENSAJE PARA CCE                          12031000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 12036000
                                              WS-TEMP-XX                12037000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 12039000
                                              WS-TEMP-XXXX              12039200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  12039300
                                                                        12039700
      *               OBTENER MENSAJE INTERNO                           12039800
                      PERFORM 5600-ACTUALIZA-COMAREA                    12040500
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002 
                      MOVE CA-IM-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-IM-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   12040600
                      PERFORM 6000-FINAL                                12040700
      *                                                                 12050000
                   WHEN OTHER                                           12050100
      *               OBTENER MENSAJE PARA CCE                          12051000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 12056000
                                              WS-TEMP-XX                12057000
                      MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO 12059000
                                              WS-TEMP-XXXX              12059200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  12059300
                                                                        12059700
      *               OBTENER MENSAJE INTERNO                           12059800
                      PERFORM 5600-ACTUALIZA-COMAREA                    12060500
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-IMDS TO WS-VARMSG-RSO            0016002 
                      MOVE CA-IM-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-IM-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   12060600
                      PERFORM 6000-FINAL                                12060700
                   END-EVALUATE                                         12200000
                END-IF                                                  12201000
           END-EVALUATE                                                 12210000
           .                                                            12211000
      ************************ FIN DE 3100-CUENTA-IMPACS                12220000
      ********************                                              12221000
       5200-CUENTA-SAVING.                                              12230000
      ********************                                              12231000
      *                                                                 12250000
           MOVE 'STDA'             TO CA-ST-COD-TRN-I                   12280000
           MOVE WS-CT-1            TO CA-ST-COD-INST-I                  12290000
      *                                                                 12300000
           STRING 'APTI'                                                12310000
                  RG-CA05-O-0A-AMBIENTE                                 12320000
                   DELIMITED BY SIZE INTO CA-ST-COD-CANAL-I             12330000
           END-STRING                                                   12340000
      *                                                                 12350000
           MOVE SPACES             TO CA-ST-COD-USU-I                   12360000
           MOVE WS-CT-S            TO CA-ST-FLAG-VERIF1-I               12370000
           MOVE WS-CT-S            TO CA-ST-FLAG-VERIF2-I               12380000
           MOVE ZEROS              TO WS-NRO-OPERACION                  12390000
           MOVE TI-CAR2-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     12400000
           MOVE WS-NRO-OPERACION           TO CA-ST-NRO-OPERACION-I     12410000
           MOVE WS-CT-01           TO CA-ST-NRO-VERSION-I               12420000
           MOVE WS-CT-0            TO CA-ST-FLAG-EXTORNO-I              12430000
           MOVE SPACES             TO CA-ST-HEADER-DISPONIBLE-I         12440000
      *                                                                 12450000
           MOVE SPACES             TO CA-ST-COD-CTA-COM-I               12460000
           MOVE TI-TRR2-CCI-CLI-BENEFICIA(4:3)                          12470000
                                   TO CA-ST-COD-CTA-COM-I(1:3)          12480000
           MOVE TI-TRR2-CCI-CLI-BENEFICIA(8:11)                         12490000
                                   TO CA-ST-COD-CTA-COM-I(4:11)         12500000
           MOVE WS-CT-001          TO CA-ST-COD-PRD-ST-I                12510000
           MOVE SPACES             TO CA-ST-FLAG-COBCOM-I               12520000
           MOVE CA-ST-HEADER-ESTANDAR-I                                 12530000
                                       TO RG-CA04-I-HDR-STD-IN          12530100
                                          RG-CA10-I-INPUT-CANAL-HEADER  12530200
      *TA000188957-I                                                            
      *    PERFORM 5200-ASIGNAR-TERM-USER                               12531000
      *    MOVE RG-CA04-I-HDR-STD-IN       TO CA-ST-HEADER-ESTANDAR-I   12540000
           MOVE 'IR99'                     TO RG-CA10-I-TERM-CICS-TETI  10951100
           MOVE 'IR0099'                   TO RG-CA10-I-K-USR-CODIGO    10951100
           MOVE RG-CA10-I-INPUT-CANAL-HEADER                            10951100
                                           TO CA-ST-HEADER-ESTANDAR-I   10951100
      *TA000188957-F                                                            
      *                                                                 12550000
           EXEC CICS LINK PROGRAM (TI-CW04-SRV-STDA)                    12560000
                          COMMAREA(CA-ST-REG-INQ)                       12570000
                          LENGTH  (LENGTH OF CA-ST-REG-INQ)             12580000
                          RESP    (WS-RESP)                             12600000
                          RESP2   (WS-RESP2)                            12610000
           END-EXEC                                                     12620000
                                                                        12630000
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         12640000
      *       OBTENER MENSAJE PARA CCE                                  12771000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  12776000
                                             WS-TEMP-XX                 12777000
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  12779000
                                             WS-TEMP-XXXX               12779200
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   12779300
              PERFORM 5600-ACTUALIZA-COMAREA                            12779700
                                                                        12779800
      *       OBTENER MENSAJE INTERNO                                   12779900
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       12780000
              SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                       12780100
              MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT     12780200
                                             WS-CODMSG-ESTRUCTURA       12780300
                                             WS-COD-ERROR-07            12780400
              MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM             12780500
                                             WS-PROGRAM                 12780600
              MOVE 'LINK'                 TO WS-VARMSG-FUN              12780700
              MOVE TI-CW04-SRV-STDA       TO WS-VARMSG-RSO              12780800
                                                                        12780900
              PERFORM 6100-OBTENER-MENSAJE                              12781000
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             12781100
                                             WS-MENSAJE-TXT-EVE         12781200
                                                                        12781300
              PERFORM 5700-GRABAR-LOG-EVENTOS                           12781400
              PERFORM 6000-FINAL                                        12781500
           ELSE                                                         12782000
              IF CA-FIN-OK-INQ OF CA-ST-REG-OUT                         12790000
                 IF (WS-CT-00 = CA-ST-STA-CTA-COD(3:2) OR               12800000
                     WS-CT-01 = CA-ST-STA-CTA-COD(3:2) OR               12810000
                     WS-CT-02 = CA-ST-STA-CTA-COD(3:2) OR               12820000
                     WS-CT-07 = CA-ST-STA-CTA-COD(3:2))                 12830000
                     CONTINUE                                           12840000
                 END-IF                                                 12850000
      *                                                                 12860000
                 IF (WS-CT-03 = CA-ST-STA-CTA-COD(3:2) OR               12870000
                     WS-CT-04 = CA-ST-STA-CTA-COD(3:2) OR               12880000
                     WS-CT-05 = CA-ST-STA-CTA-COD(3:2))                 12890000
      *              OBTENER MENSAJE PARA CCE                           13021000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 13026000
                                              WS-TEMP-XX                13027000
                     MOVE WS-CT-AC07       TO TI-CF06-COD-RESP-AMPLIADO 13029000
                                              WS-TEMP-XXXX              13029200
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  13029300
                                                                        13029700
      *                OBTENER MENSAJE INTERNO                          13029800
                                                                        13030400
                                                                        13030500
                     PERFORM 5600-ACTUALIZA-COMAREA                     13030600
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES       0827190
                     SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                 0827200
                     MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                     MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                     MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO              0016002
                     MOVE CA-ST-STA-CTA-COD(3:2)                         0827280
                                           TO WS-VARMSG-ARG              0827280
                     MOVE CA-ST-STA-CTA-DES                              0827280
                                           TO WS-VARMSG-TXT              0827280
                                                                         0827290
                     PERFORM 6100-OBTENER-MENSAJE                        0827300
                     MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG             0827310
                                              WS-MENSAJE-TXT-EVE         0827320
                     PERFORM 5700-GRABAR-LOG-EVENTOS                    13030700
                     PERFORM 6000-FINAL                                 13030800
                 END-IF                                                 13031000
      *                                                                 13040000
                 IF (WS-CT-06 = CA-ST-STA-CTA-COD(3:2) OR               13050000
                     WS-CT-08 = CA-ST-STA-CTA-COD(3:2))                 13060000
      *              OBTENER MENSAJE PARA CCE                           13141000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 13146000
                                              WS-TEMP-XX                13147000
                     MOVE WS-CT-AC06       TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-TEMP-XXXX              00160022
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  13149300
                                                                        13149700
      *                OBTENER MENSAJE INTERNO                          13149800
                                                                        13150400
                                                                        13150500
                     PERFORM 5600-ACTUALIZA-COMAREA                     13150600
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES       0827190
                     SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                 0827200
                     MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT     0827210
                                              WS-CODMSG-ESTRUCTURA       0827220
                                              WS-COD-ERROR-07            0827230
                     MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM             0827240
                                              WS-PROGRAM                 0827250
                     MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO              0016002
                     MOVE CA-ST-STA-CTA-COD(3:2)                         0827280
                                           TO WS-VARMSG-ARG              0827280
                     MOVE CA-ST-STA-CTA-DES                              0827280
                                           TO WS-VARMSG-TXT              0827280
                                                                         0827290
                     PERFORM 6100-OBTENER-MENSAJE                        0827300
                     MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG             0827310
                                              WS-MENSAJE-TXT-EVE         0827320
                     PERFORM 5700-GRABAR-LOG-EVENTOS                    13150700
                     PERFORM 6000-FINAL                                 13150800
                 END-IF                                                 13151000
              ELSE                                                      13160000
                 EVALUATE CA-ST-COD-RET                                 13170000
                   WHEN WS-CT-ST0316                                    13180000
      *               OBTENER MENSAJE PARA CCE                          13261000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13266000
                                              WS-TEMP-XX                13267000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 13269000
                                              WS-TEMP-XXXX              13269200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13269300
                                                                        13269700
      *               OBTENER MENSAJE INTERNO                           13269800
                                                                        13270500
                      PERFORM 5600-ACTUALIZA-COMAREA                    13270600
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO            0016002 
                      MOVE CA-ST-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-ST-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   13270700
                      PERFORM 6000-FINAL                                13270800
                   WHEN WS-CT-ST0404                                    13271000
      *               OBTENER MENSAJE PARA CCE                          13351000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13356000
                                              WS-TEMP-XX                13357000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 13359000
                                              WS-TEMP-XXXX              13359200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13359300
                                                                        13359700
      *               OBTENER MENSAJE INTERNO                           13359800
                                                                        13360500
                      PERFORM 5600-ACTUALIZA-COMAREA                    13360600
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO            0016002 
                      MOVE CA-ST-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-ST-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   13360700
                      PERFORM 6000-FINAL                                13360800
                   WHEN WS-CT-ST0604                                    13361000
      *               OBTENER MENSAJE PARA CCE                          13441000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13446000
                                              WS-TEMP-XX                13447000
                      MOVE WS-CT-AC01      TO TI-CF06-COD-RESP-AMPLIADO 13449000
                                              WS-TEMP-XXXX              13449200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13449300
                                                                        13449700
      *               OBTENER MENSAJE INTERNO                           13449800
                                                                        13450500
                      PERFORM 5600-ACTUALIZA-COMAREA                    13450600
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO            0016002 
                      MOVE CA-ST-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-ST-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   13450700
                      PERFORM 6000-FINAL                                13450800
                   WHEN OTHER                                           13451000
      *               OBTENER MENSAJE PARA CCE                          13571000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13576000
                                              WS-TEMP-XX                13577000
                      MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO 13579000
                                              WS-TEMP-XXXX              13579200
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13579300
                                                                        13579700
      *               OBTENER MENSAJE INTERNO                           13579800
                      PERFORM 5600-ACTUALIZA-COMAREA                    13580500
                      MOVE SPACES           TO TI-CA15-I-O-MENSAJES     0827190 
                      SET  TI-CA15-I-RC-APP-TTIB  TO TRUE               0827200 
                      MOVE 'TI0412'         TO TI-CF06-CODMSG-ESTRUCT   0827210 
                                               WS-CODMSG-ESTRUCTURA     0827220 
                                               WS-COD-ERROR-07          0827230 
                      MOVE WS-PROGRAM-ID    TO TI-CF06-PRGNOM           0827240 
                                               WS-PROGRAM               0827250 
                      MOVE TI-CW04-SRV-STDA TO WS-VARMSG-RSO            0016002 
                      MOVE CA-ST-COD-RET    TO WS-VARMSG-ARG            0827280 
                      MOVE CA-ST-TXT-RET    TO WS-VARMSG-TXT            0827280 
                                                                        0827290 
                      PERFORM 6100-OBTENER-MENSAJE                      0827300 
                      MOVE WS-MENSAJE-TXT   TO TI-CF06-TXTMSG           0827310 
                                               WS-MENSAJE-TXT-EVE       0827320 
                      PERFORM 5700-GRABAR-LOG-EVENTOS                   13580600
                      PERFORM 6000-FINAL                                13580700
                 END-EVALUATE                                           13581000
              END-IF                                                    13590000
              .                                                         13590100
      ************************ FIN DE 3200-CUENTA-SAVING                13591000
      *GNS-F                                                                    
      *GNS-I                                                                    
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
      *GNS-F                                                                    
      ***************                                                   16400000
       9000-TERMINAR.                                                   16410000
      ***************                                                   16420000
                                                                        16430000
      *GNS-I                                                                    
      *    SET TI-CF06-88-ACEP             TO TRUE                      16481000
           IF TI-CAR2-88-COD-PROCESO-CNF                                        
               SET TI-CF06-88-ACEP         TO TRUE                      16481000
JCS   *MVP00139677--\                                                           
               MOVE WS-CT-00          TO TI-CF06-RESPONSE-CODE-CCE              
               MOVE WS-CT-0000        TO TI-CF06-COD-RESP-AMPLIADO              
               MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA               
               MOVE WS-CT-00          TO TI-TRR2-RESPONSE-CODE-CCE              
               MOVE WS-CT-0000        TO TI-TRR2-COD-RESP-AMPLIADO              
JCS   *MVP00139677--/                                                           
           ELSE                                                                 
               SET TI-CF06-88-RECH         TO TRUE                      16481000
JCS   *MVP00139677--\                                                           
               MOVE WS-CT-05          TO TI-CF06-RESPONSE-CODE-CCE              
               MOVE WS-CT-DS24        TO TI-CF06-COD-RESP-AMPLIADO              
               MOVE WS-CT-001         TO TI-CF06-ORIGEN-RESPUESTA               
               MOVE WS-CT-05          TO TI-TRR2-RESPONSE-CODE-CCE              
               MOVE WS-CT-DS24        TO TI-TRR2-COD-RESP-AMPLIADO              
JCS   *MVP00139677--/                                                           
           END-IF                                                               
      *GNS-F                                                                    
JCS   *MVP00139677--\                                                           
      *    MOVE WS-CT-00                   TO TI-CF06-RESPONSE-CODE-CCE 16482000
      *    MOVE WS-CT-0000                 TO TI-CF06-COD-RESP-AMPLIADO 16483000
      *    MOVE WS-CT-001                  TO TI-CF06-ORIGEN-RESPUESTA  16484000
JCS   *MVP00139677--/                                                           
      *GNS-I                                                                    
      *    MOVE WS-CT-TRANSOK              TO TI-CF06-MENSAJE-RESPUESTA 16485000
           MOVE SPACES                     TO TI-CF06-MENSAJE-RESPUESTA 16485000
           MOVE SPACES                     TO TI-CF06-CODMSG-ESTRUCT    16485000
           MOVE SPACES                     TO TI-CF06-PRGNOM            16485000
           MOVE SPACES                     TO TI-CF06-TXTMSG            16485000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *    MOVE WS-IDC                     TO TI-CF06-IDC-BEN           16490000
      *GNS-F                                                                    
      *GNS-I                                                                    
      *    IF  TI-TR02-MSGE-TYPE-ID = WS-CT-0201                        16491000
           IF  TI-TRR2-88-SI-REENV                                      16491000
      *GNS-F                                                                    
               SET  TI-CF06-88-SI-REENV     TO TRUE                     16491100
      *GNS-I                                                                    
      *        MOVE TI-TR02-TIPO-PROCESO    TO TI-CF06-TIPO-PROCESO     16491200
               MOVE TI-TRR2-TIPO-PROCESO    TO TI-CF06-TIPO-PROCESO     16491200
      *GNS-F                                                                    
      *GNS-I                                                                    
               MOVE TI-TRR2-NUMERO-REINTENTOS                           16491000
                                            TO TI-CF06-NUM-REINTE       16491000
      *GNS-F                                                                    
      *GNS-I                                                                    
               IF  TI-TRR2-88-TIP-PROC-BATCH                            16491000
                   MOVE 'REGULARIZACION BATCH'                          16485000
                                            TO TI-CF06-MENSAJE-RESPUESTA16485000
               END-IF                                                   16491000
      *GNS-F                                                                    
           END-IF                                                       16493000
                                                                        16500000
           PERFORM 5500-ACTUALIZA-MASTER-TRANSF                         16510000
      *GNS-I                                                                    
           IF  TI-TRR2-88-TIP-PROC-LINEA                                16491000
               PERFORM 5550-BORRA-ARCHIVO-REINTENTOS                    16510000
           END-IF                                                       16491000
      *GNS-F                                                                    
                                                                        16520000
      *GNS-I                                                                    
      *    MOVE WS-CT-00                   TO TI-TR02-RESPONSE-CODE-CCE 16561000
      *    MOVE WS-CT-0000                 TO TI-TR02-COD-RESP-AMPLIADO 16562000
      *    MOVE WS-CT-001                  TO TI-TR02-ORIGEN-RESPUESTA  16563000
      *    MOVE WS-CT-TRANSOK              TO TI-TR02-MENSAJE-RESPUESTA 16564000
      *    MOVE WS-CT-TRANSOK              TO WS-MENSAJE-TXT            16565000
      *    MOVE WS-CT-0000                 TO WS-CT-NUMER               16566000
JCS   *MVP00139677--\                                                           
      *    MOVE WS-CT-00                   TO TI-TRR2-RESPONSE-CODE-CCE 16561000
      *    MOVE WS-CT-0000                 TO TI-TRR2-COD-RESP-AMPLIADO 16562000
JCS   *MVP00139677--/                                                           
      *GNS-F                                                                    
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
      *GNS-I                                                                    
      *    SET  WS-SI-EXISTE-ERROR         TO TRUE                      16770000
      *GNS-F                                                                    
           MOVE WS-CT-001                         TO WS-CODMSG          16780000
           MOVE WS-ABCODE                  TO WS-TXTMSG                 16790000
      *GNS-I                                                                    
           MOVE WS-CODMSG-ESTRUCTURA       TO WS-CSMT-COD-RETORNO       05800000
           MOVE WS-COD-PROG                TO WS-CSMT-COD-PROGRAMA      05800000
           MOVE WS-TXTMSG                  TO WS-CSMT-MENSAJE           05800000
           PERFORM 6400-WRITE-CSMT                                      00160022
      *GNS-F                                                                    
           PERFORM 6000-FINAL                                           16800000
           .                                                            16810000
      ************************ FIN DE 9999-MANEJO-EXCEPCIONES           16820000
