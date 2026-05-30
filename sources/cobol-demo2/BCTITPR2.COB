       IDENTIFICATION DIVISION.                                         00010000
       PROGRAM-ID.    BCTITPR2.                                         00020000
       AUTHOR.        TCS - DANTE PANDO FLORES.                         00030000
       INSTALLATION.  BANCO DE CREDITO.                                 00040000
       DATE-WRITTEN.  ENE - 2015.                                       00050000
      ******************************************************************00060000
      *                    PROPIEDAD DEL PROGRAMA                      *00070000
      *                                                                *00080000
      *   ESTE PROGRAMA Y SUS ELEMENTOS ASOCIADOS SON DE PROPIEDAD     *00090000
      *   DEL BANCO DE CREDITO DEL PERU Y NO PUEDE SER REPRODUCIDO,    *00100000
      *   DIVULGADO O UTILIZADO SIN UNA LICENCIA O AUTORIZACION        *00110000
      *   ESCRITA OTORGADA POR EL BANCO DE CREDITO DEL PERU.           *00120000
      *                                                                *00130000
      ******************************************************************00140000
      *                                                                *00150000
      * MODULO    : TRANSFERENCIAS DE TTIB                             *00160000
      *                                                                *00170000
      * OBJETIVOS :                                                    *00180000
      *                                                                *00190000
      *                                                                *00200000
      * FUNCIONES : 1. SE IMPLEMENTARA EL SERVICIO QUE SER¡ INVOCADO   *00210000
      *                POR SIX/STI DE NOVATRONIC CUANDO EL BCP SEA     *00220000
      *                RECEPTOR                                        *00230000
      *                                                                *00240000
      *             2. GENERAR TRAMA DE CONSULTA A SYSTEMATICS O VISION*00250000
      *                PLUS                                            *00260000
      *                                                                *00270000
      *             3. VALIDAR QUE LA MONEDA SEA LA MISMA DE LA CUENTA *00280000
      *                DE ABONO                                        *00290000
      *                                                                *00300000
      *             4. VALIDAR SI LA CUENTA PERTENECE AL IDC DEL       *00310000
      *                BENEFICIARIO                                    *00320000
      *                                                                *00330000
      *             5. OBTENER MANCONUMOS DESDE CONSIST PARA CUENTAS   *00340000
      *                DE SYSTEMATICS. ESTO EN CASO EL IDC ENVIADO     *00350000
      *                NO COINCIDA                                     *00360000
      *                                                                *00370000
      * RUTINAS   :                                                    *00380000
      *                                                                *00390000
      *   BCNDAO05  RUTINA PARA VER EL ESTADO DE NEXT-DAY              *00400000
      ******************************************************************00410000
      *                                                                 00069579
      *----------------------------------------------------------------*00069579
      *              C O N T R O L   D E   C A M B I O S               *00069579
      *----------------------------------------------------------------*00069579
      * MODIFICACION  : MODIFICAR PROGRAMA PARA IMPLEMENTAR 24X7       *00160022
      * FECHA         : 03/08/2020                                     *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: MPM                                            *00160022
      * NRO.TICKET    : TA000160022                                    *00160022
      ******************************************************************00160022
      *  MODIFICACION   : SN000064789-ST000065143                      *00069579
      *                 : MEJORAS VARIAS PARA TIN INMEDIATAS           *00069579
      *  FECHA          : 22/09/2016                                   *00069579
      *  AFECTA A       : BCP                                          *00069579
      *  MODIFICADO POR : LENIN QUIROZ - TCS                           *00069579
      *  NRO.TICKET     : TK000069579                                  *00069579
      *----------------------------------------------------------------*00069579
      * MODIFICACION  : VOCALINK                                       *00160022
      * FECHA         : 2022                                           *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : TA000184140                                    *00160022
      ******************************************************************00160022
      *                                                                 00069579
      **********************                                            00419400
       ENVIRONMENT DIVISION.                                            00420000
      **********************                                            00430000
       DATA DIVISION.                                                   00440000
      *************************                                         00450000
       WORKING-STORAGE SECTION.                                         00460000
      *************************                                         00470000
       01  WS-VARIABLES-GENERALES.                                      00480000
           05  WS-PROGRAM-ID             PIC  X(08)  VALUE 'BCTITPR2'.  00490000
           05  WS-PROGRAM                PIC  X(08)  VALUE SPACES.      00491000
           05  WS-RTN-SGTE               PIC  X(08)  VALUE SPACES.      00500000
           05  WS-DGC-NUM-ICLI           PIC  X(08)  VALUE SPACES.      00510000
           05  WS-PROG-CALLER            PIC  X(08)  VALUE 'BCTITPE0'.  00520000
           05  WS-MENSAJE-TXT            PIC  X(80)  VALUE SPACES.      00530000
           05  WS-MENSAJE-TXT-EVE        PIC  X(80)  VALUE SPACES.      00531000
           05  WS-CUENTA-PROPIA-SI       PIC  9(01)  VALUE 0.           00540000
           05  WS-FLG-BCIMYR8S           PIC  X(06)  VALUE SPACES.      00550000
           05  WS-FLG-BCSTYR80           PIC  X(06)  VALUE SPACES.      00560000
           05  WS-TIPO-DOC-ORD-HOMOL     PIC  X(01)  VALUE SPACES.      00570000
           05  WS-DOC-ORD-CONST        PIC  X(12)  VALUE '000000000000'.00571000
           05  WS-DOC-ORD-CONSIST      PIC  X(12)  VALUE SPACES.        00571100
           05  WS-DOC-ORD-CCE          PIC  X(12)  VALUE SPACES.        00572000
           05  WS-DOC-ORD-TMP          PIC  X(12)  VALUE SPACES.        00573000
           05  WS-DOC-ORD-TMP2         PIC  X(12)  VALUE SPACES.        00574000
           05  WS-POS                  PIC  9(02)  VALUE ZEROS.         00580000
           05  WS-POS-INI              PIC  9(02)  VALUE ZEROS.         00580100
           05  WS-LENGHT-CAD           PIC  9(02)  VALUE ZEROS.         00580200
           05  INDOK                     PIC  9(02)  VALUE ZEROS.       00581000
           05  WS-TMP-ICLI               PIC  X(08).                    00590000
           05  WS-RES                    PIC  9(02).                    00600000
           05  WS-RTN-BCRGTP05           PIC  X(08)  VALUE 'BCRGTP05'.  00610000
           05  WS-RTN-BCIMTP27           PIC  X(08)  VALUE 'BCIMTP27'.  00620000
           05  WS-RTN-BCSTTP10           PIC  X(08)  VALUE 'BCSTTP10'.  00630000
           05  WS-RTN-ASIGNA-TETI        PIC  X(08)  VALUE 'BCRGTP04'.  00640000
           05  WS-RTN-SGCPPDGC           PIC  X(08)  VALUE 'SGCPPDGC'.  00650000
           05  WS-RTN-BCVPTP28           PIC  X(08)  VALUE 'BCVPTP28'.  00660000
           05  WS-RTN-BCRGTP04           PIC  X(08)  VALUE 'BCRGTP04'.  00670000
           05  WS-RTN-MENSAJES           PIC  X(08)  VALUE 'BCTITP15'.  00671000
      *    05  WS-VARMSG-RSO             PIC  X(08)  VALUE SPACES.      00680000
           05  WS-USUARIO                PIC  X(07)  VALUE '       '.   00690000
           05  WS-EYEID-ND               PIC  X(10)  VALUE 'NEXTDAYCOM'.00700000
           05  WS-APLID-SYST             PIC  X(04)  VALUE 'TTIB'.      00710000
           05  WS-TSIS-TTIB              PIC  X(08)  VALUE 'BCTIAV03'.  00720000
           05  WS-ABSTIME-PROC           PIC S9(15) COMP-3 VALUE +0.    00730000
           05  WS-VALIDA-PRG1            PIC  9(01)  VALUE 0.           00740000
           05  WS-TX-MSJE                PIC  X(80)  VALUE SPACES.      00750000
           05  WS-TMP-VC1                PIC  9(01)  VALUE 0.           00760000
           05  WS-TMP-CC1                PIC  X(30)  VALUE SPACES.      00770000
           05  WS-TR02-MSGE-TYPE-ID      PIC  X(30)                     00790000
                                         VALUE 'TI-TR02-MSGE-TYPE-ID'.  00800000
           05  WS-TR02-COD-PROCESO       PIC  X(30)                     00810000
                                         VALUE 'TI-TR02-COD-PROCESO '.  00820000
           05  WS-NRO-OPERACION          PIC 9(08)  VALUE 0.            00830000
           05  WS-I-TRAMA                PIC X(1600).                   00840000
           05  WS-CT-10C                 PIC X(03)    VALUE '010'.      00850000
           05  WS-CT-08C                 PIC X(03)    VALUE '008'.      00860000
           05  WS-CT-05C                 PIC X(03)    VALUE '005'.      00870000
           05  WS-CT-BCO                 PIC X(03)    VALUE '002'.      00871000
                                                                        00880000
           05  WS-I                      PIC  9(04).                    00881000
           05  WS-LGTH-TEM               PIC S9(04) COMP VALUE 0.       00890000
           05  WS-PTR-TSIS-N             PIC S9(08) COMP VALUE 0.       00900000
           05  WS-PTR-TSIS-X   REDEFINES                                00910000
               WS-PTR-TSIS-N             PIC  X(04).                    00920000
           05  WS-PTR-TSIS     REDEFINES                                00930000
               WS-PTR-TSIS-N              USAGE IS POINTER.             00940000
           05  WS-BCOPZA.                                               00950000
               10 WS-CODREGI             PIC 9(02).                     00960000
               10 WS-BCODEST             PIC X(03).                     00970000
               10 WS-PZADEST             PIC X(03).                     00980000
           05  WS-LIMITE.                                               00990000
               10 WS-TIPPARM             PIC 9(02).                     01000000
               10 WS-TIPTRANS            PIC X(03).                     01010000
               10 WS-MONBCP              PIC X(04).                     01020000
               10 WS-TIPPZA              PIC X(01).                     01030000
               10 FILLER                 PIC X(20).                     01040000
           05 WS-FECHA-HORA-PROC.                                       01050000
               10 WS-FECHA-PROC          PIC 9(4).                      01060000
               10 WS-HORA-PROC           PIC 9(6).                      01070000
           05  WS-AREAID-I-CNL           PIC X(08).                     01080000
           05  WS-LGTH-I-OPE             PIC S9(04)  COMP VALUE 0.      01090000
           05  WS-LGTH-I-CNL             PIC S9(04)  COMP VALUE 0.      01100000
           05  WS-LGTH-O-CNL             PIC S9(04)  COMP VALUE 0.      01110000
           05  WS-PTR-I-CNL              USAGE IS POINTER.              01120000
           05  WS-PTR-I-CNL-X REDEFINES                                 01130000
               WS-PTR-I-CNL              PIC  X(04).                    01140000
           05  WS-PTR-I-CNL-N REDEFINES                                 01150000
               WS-PTR-I-CNL              PIC S9(08)  COMP.              01160000
           05  WS-RBA-ESDS               PIC S9(08)  COMP.              01170000
           05  WS-CADENA-TXT             PIC X(80).                     01180000
           05  WS-SYSID-LOC              PIC X(04) VALUE SPACES.        01190000
           05  WS-ABCODE                 PIC X(04) VALUE SPACES.        01200000
           05  WS-ABPROGRAM              PIC X(08) VALUE SPACES.        01210000
           05  WS-ABSTIME                PIC S9(15) COMP-3 VALUE +0.    01220000
           05  WS-FECHA-INI.                                            01230000
               10  WS-FEINI-CICS         PIC 9(08) VALUE 0.             01240000
               10  FILLE1                PIC X(02) VALUE SPACES.        01250000
           05  WS-HORA-INI.                                             01260000
               10  WS-HOINI-CICS         PIC X(08) VALUE SPACES.        01270000
           05  WS-NUM-SEGUNDOS           PIC S9(08) COMP  VALUE +1.     01280000
           05  WS-HORA-SS-INI            PIC 9(04) VALUE 0.             01290000
           05  WS-HORA-SS-FIN            PIC 9(04) VALUE 0.             01300000
           05  WS-HORA-SS-CNL            PIC 9(04) VALUE 0.             01310000
           05  WS-FECHA-FIN.                                            01320000
               10  WS-FEFIN-CICS         PIC 9(08) VALUE 0.             01330000
               10  FILLE2                PIC X(02) VALUE SPACES.        01340000
           05  WS-HORA-FIN.                                             01350000
               10 WS-HOFIN-CICS          PIC X(08) VALUE SPACES.        01360000
           05  WS-TIEMPO-PROC            PIC 9(03) VALUE ZEROS.         01370000
                                                                        01380000
           05  WS-RECURSOS-CICS.                                        01390000
               10  WS-TIPO-CONEX         PIC  X(02) VALUE '  '.         01400000
                   88  WS-CONEX-LINK          VALUE 'D ' 'DS'.          01410000
                   88  WS-CONEX-START         VALUE 'S ' 'SD' 'SZ'.     01420000
                   88  WS-CONEX-TRIGGER       VALUE 'QD'.               01430000
                   88  WS-CONEX-SEND          VALUE 'TD'.               01440000
                   88  WS-CONEX-TASK          VALUE 'U '.               01450000
               10  WS-TRANID             PIC  X(04) VALUE SPACES.       01460000
               10  WS-CONVID             PIC  X(04) VALUE SPACES.       01470000
               10  WS-APPLID             PIC  X(08) VALUE SPACES.       01480000
                                                                        01490000
           05  WS-IDC                    PIC X(16)   VALUE SPACES.      01500000
           05  WS-RESP                   PIC S9(08)  COMP VALUE +0.     01510000
           05  WS-RESP2                  PIC S9(08)  COMP VALUE +0.     01520000
           05  WS-RESP-TXT               PIC X(08)   VALUE SPACES.      01530000
           05  WS-CODIGO-RESP            PIC X(06).                     01550000
           05  WS-LONGITUD-RESP          PIC 9(05).                     01560000
           05  WS-IMPORTE                PIC X(20).                     01570000
           05  WS-IMPORTE-12             PIC X(12).                     01580000
           05  WS-IMPORTE-NV REDEFINES WS-IMPORTE-12   PIC 9(12).       01590000
           05  WS-CCAA                   PIC X(32000).                  01600000
           05  WS-LGTH-CCAA              PIC S9(04)  VALUE +0 COMP.     01610000
           05  WS-CT-NUMER               PIC 9(04)   VALUE ZEROS.       01620000
           05  WS-TEMP-XX                PIC X(02)   VALUE SPACES.      01621000
           05  WS-X                      PIC 9(2)    VALUE ZEROS.       01630000
           05  WS-J                      PIC 9(1)    VALUE 0.           01631000
           05  WS-K                      PIC 9(1)    VALUE 0.           01640000
      *                                                                 01650000
       01  WS-RPTA-MSG.                                                 01660000
           05  WS-CODMSG-ESTRUCTURA.                                    01670000
               10  WS-CODAPP             PIC  X(02)  VALUE 'TI'.        01680000
               10  WS-CODTIP             PIC  X(02).                    01690000
                   88  WS-CODTIP-88-CONFORME         VALUE '00'.        01700000
                   88  WS-CODTIP-88-ERROR-CONSIST    VALUE '04'.        01710000
                   88  WS-CODTIP-88-ERROR-RECURSOS   VALUE '08'.        01720000
                   88  WS-CODTIP-88-ERROR-AUTORIZ    VALUE '16'.        01730000
               10  WS-CODMSG             PIC  X(02).                    01740000
           05  WS-TXTMSG                 PIC  X(80)  VALUE SPACES.      01750000
           05  WS-COD-ESTADO             PIC  X(02).                    01760000
               88  WS-COD-ACEP               VALUE '00'.                01770000
               88  WS-COD-PEND               VALUE '01'.                01780000
               88  WS-COD-RECH               VALUE '02'.                01790000
           05  WS-COD-PROG               PIC  X(08)  VALUE 'BCTITPR2'.  01800000
      *                                                                 01810000
      * AHORROS - SAVING                                                01820000
           05 WS-CTA-ING-SAV.                                           01830000
              10 WS-COD-SUC-SAV          PIC  X(03)  VALUE SPACES.      01840000
              10 WS-NRO-CTA-SAV          PIC  X(08)  VALUE SPACES.      01850000
              10 WS-COD-MON-SAV          PIC  X(01)  VALUE SPACES.      01860000
              10 WS-DIG-VER-SAV          PIC  X(02)  VALUE SPACES.      01870000
      *                                                                 01880000
       01  WS-CONSTANTES.                                               01890000
           05  WS-MONTO-20               PIC X(20) VALUE                01900000
               ' 00000000000000.0000'.                                  01910000
           05  WS-CT-TI                  PIC X(02) VALUE 'TI'.          01920000
           05  WS-CT-00                  PIC X(02) VALUE '00'.          01930000
           05  WS-CT-02                  PIC X(02) VALUE '02'.          01940000
           05  WS-CT-03                  PIC X(02) VALUE '03'.          01950000
           05  WS-CT-04                  PIC X(02) VALUE '04'.          01960000
           05  WS-CT-05                  PIC X(02) VALUE '05'.          01970000
           05  WS-CT-06                  PIC X(02) VALUE '06'.          01980000
           05  WS-CT-07                  PIC X(02) VALUE '07'.          01990000
           05  WS-CT-08                  PIC X(02) VALUE '08'.          02000000
           05  WS-CT-09                  PIC X(02) VALUE '09'.          02010000
           05  WS-CT-004                 PIC X(03) VALUE '004'.         02020000
           05  WS-CT-005                 PIC X(03) VALUE '005'.         02030000
           05  WS-CT-0200                PIC X(04) VALUE '0200'.        02040000
           05  WS-CT-0201                PIC X(04) VALUE '0201'.        02050000
           05  WS-CT-1016                PIC X(04) VALUE '1016'.        02060000
           05  WS-CT-SPACE4              PIC X(04) VALUE SPACES.        02061000
           05  WS-CT-800000              PIC X(06) VALUE '800000'.      02070000
           05  WS-CT-490000              PIC X(06) VALUE '490000'.      02080000
           05  WS-CT-840                 PIC X(06) VALUE '840'.         02090000
           05  WS-CTN-0                  PIC 9(01) VALUE 0.             02100000
           05  WS-CTN-1                  PIC 9(01) VALUE 1.             02110000
           05  WS-CTN-12                 PIC 9(02) VALUE 12.            02120000
           05  WS-CT-L                   PIC X(01) VALUE 'L'.           02130000
           05  WS-CT-1006                PIC X(04) VALUE '1006'.        02140000
           05  WS-CT-1021                PIC X(04) VALUE '1021'.        02150000
           05  WS-CT-001                 PIC X(03) VALUE '001'.         02170000
           05  WS-CT-320                 PIC X(03) VALUE '320'.         02180000
           05  WS-CT-325                 PIC X(03) VALUE '325'.         02190000
           05  WS-CT-604                 PIC X(03) VALUE '604'.         02200000
           05  WS-CT-804                 PIC X(03) VALUE '804'.         02210000
           05  WS-CT-1005                PIC X(04) VALUE '1005'.        02230000
           05  WS-CT-1002                PIC X(04) VALUE '1002'.        02240000
           05  WS-CT-IM0304              PIC X(06) VALUE 'IM0304'.      02250000
           05  WS-CT-IM0316              PIC X(06) VALUE 'IM0316'.      02260000
           05  WS-CT-IM0504              PIC X(06) VALUE 'IM0504'.      02270000
           05  WS-CT-IM0604              PIC X(06) VALUE 'IM0604'.      02280000
           05  WS-CT-1003                PIC X(04) VALUE '1003'.        02290000
           05  WS-CT-1001                PIC X(04) VALUE '1001'.        02300000
           05  WS-CT-ST0316              PIC X(06) VALUE 'ST0316'.      02310000
           05  WS-CT-ST0404              PIC X(06) VALUE 'ST0404'.      02320000
           05  WS-CT-ST0604              PIC X(06) VALUE 'ST0604'.      02330000
           05  WS-CT-4                   PIC X(01) VALUE '4'.           02350000
           05  WS-CT-0000                PIC X(04) VALUE '0000'.        02360000
           05  WS-CT-1B                  PIC X(01) VALUE ' '.           02380000
           05  WS-CT-M                   PIC X(01) VALUE 'M'.           02380100
           05  WS-CT-O                   PIC X(01) VALUE 'O'.           02381000
           05  WS-CT-0                   PIC X(01) VALUE '0'.           02390000
           05  WS-CT-0002                PIC X(04) VALUE '0002'.        02410000
           05  WS-CT-0003                PIC X(04) VALUE '0003'.        02420000
           05  WS-CT-0009                PIC X(04) VALUE '0009'.        02430000
           05  WS-CT-1007                PIC X(04) VALUE '1007'.        02440000
           05  WS-CT-2002                PIC X(04) VALUE '2002'.        02450000
           05  WS-CT-2008                PIC X(04) VALUE '2008'.        02460000
           05  WS-CT-1008                PIC X(04) VALUE '1008'.        02470000
           05  WS-CT-111                 PIC X(04) VALUE '111'.         02480000
           05  WS-CT-054                 PIC X(04) VALUE '054'.         02490000
           05  WS-CT-1                   PIC X(01) VALUE '1'.           02500000
           05  WS-CT-SL                  PIC X(02) VALUE 'SL'.          02510000
           05  WS-CT-1009                PIC X(04) VALUE '1009'.        02520000
           05  WS-CT-15                  PIC X(02) VALUE '15'.          02540000
           05  WS-CT-1021N               PIC 9(04) VALUE 1021.          02550000
           05  WS-CT-9999N               PIC 9(04) VALUE 9999.          02560000
           05  WS-CT-1001N               PIC 9(04) VALUE 1001.          02570000
           05  WS-CT-1005N               PIC 9(04) VALUE 1005.          02580000
           05  WS-CT-1002N               PIC 9(04) VALUE 1002.          02590000
           05  WS-CT-1006N               PIC 9(04) VALUE 1006.          02600000
           05  WS-CT-1003N               PIC 9(04) VALUE 1003.          02610000
           05  WS-CT-1016N               PIC 9(04) VALUE 1016.          02620000
           05  WS-CT-1007N               PIC 9(04) VALUE 1007.          02630000
           05  WS-CT-1008N               PIC 9(04) VALUE 1008.          02640000
           05  WS-CT-1009N               PIC 9(04) VALUE 1009.          02650000
           05  WS-CT-0000N               PIC 9(04) VALUE 0000.          02660000
           05  WS-CT-TRANSOK             PIC X(14)                      02670000
                                         VALUE 'TRANSACCION-OK'.        02680000
           05  WS-CT-8N                  PIC 9(01) VALUE 8.             02690000
           05  WS-CT-5N                  PIC 9(01) VALUE 5.             02700000
           05  WS-CT-1N                  PIC 9(01) VALUE 1.             02710000
           05  WS-CT-2N                  PIC 9(01) VALUE 2.             02711000
           05  WS-CT-6N                  PIC 9(01) VALUE 6.             02720000
           05  WS-CT-S                   PIC X(01) VALUE 'S'.           02730000
           05  WS-CT-01                  PIC X(02) VALUE '01'.          02740000
           05  WS-CT-8                    PIC X(01) VALUE '8'.          02760000
           05  WS-CT-5                    PIC X(01) VALUE '5'.          02770000
           05  WS-CT-0001                 PIC X(04) VALUE '0001'.       02780000
           05  WS-COD-ERROR-07            PIC X(06) VALUE '000000'.     02820000
           05  WS-CT-A                    PIC X(01) VALUE 'A'.          02830000
           05  WS-CT-6                    PIC X(01) VALUE '6'.          02840000
           05  WS-CONTA-C                 PIC 9(02) VALUE ZEROS.        02850000
           05  IND-TMP                    PIC 9(01) VALUE 0.            02860000
           05  IND                        PIC 9(02) VALUE ZEROS.        02870000
           05  WS-CT-LETNUM.                                            02880000
               10 WS-CT-NUM              PIC X(10) VALUE '0123456789'.  02890000
               10 WS-CT-LET              PIC X(26) VALUE                02900000
                                         'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.  02910000
       01  WS-CONVERSIONES.                                             02920000
           05 WS-TI-TR02-IMPOR1       PIC  9(12).                       02930000
           05 WS-TR02-IMPORTE-R       REDEFINES WS-TI-TR02-IMPOR1       02940000
                                      PIC S9(10)V99.                    02950000
           05 WS-TI-TR02-IMPOR1       PIC  9(15).                       02960000
           05 WS-TR02-IMPORTE-COMI-R  REDEFINES WS-TI-TR02-IMPOR1       02970000
                                      PIC S9(13)V99.                    02980000
                                                                        00160022
       01  WS-FILE-NAME-TTIB.                                           00160022
           05  WS-FILE-NM-MAESTRO          PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT      PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-MAESTRO-ALT2     PIC  X(08)  VALUE SPACES.    00160022
           05  WS-FILE-NM-EVEN-LOG         PIC  X(08)  VALUE SPACES.    00160022
                                                                        00160022
       01  WS-CONTADORES-FILES.                                         02990000
           10 WS-NC-COUNTER-NAME       PIC  X(16) VALUE SPACES.         03000000
           10 WS-NRO-OPER-COUNTER      PIC S9(08)  COMP  VALUE +0.      03010000
       01  WS-SWITCHES.                                                 03070000
           05  WS-EXISTE-ERROR           PIC  X(01)  VALUE 'N'.         03080000
               88  WS-NO-EXISTE-ERROR                VALUE 'N'.         03090000
               88  WS-SI-EXISTE-ERROR                VALUE 'S'.         03100000
                                                                        03110000
           05  WS-TRANSFER-ENCONTRADO    PIC  X(01)  VALUE 'N'.         03120000
               88  WS-TRANSFER-ENCONTRADO-OK         VALUE 'N'.         03130000
               88  WS-TRANSFER-ENCONTRADO-NOOK       VALUE 'S'.         03140000
                                                                        03150000
           05  WS-TRAMA-INPUT            PIC  X(01)  VALUE 'N'.         03160000
               88  WS-TRAMAINP-OK                    VALUE 'N'.         03170000
               88  WS-TRAMAINP-NOOK                  VALUE 'S'.         03180000
                                                                        03190000
           05  WS-CANAL-ENCONTRADO       PIC  X(01)  VALUE 'N'.         03200000
               88  WS-CANAL-ENCONTRADO-OK            VALUE 'S'.         03210000
               88  WS-CANAL-ENCONTRADO-NOOK          VALUE 'N'.         03220000
                                                                        03230000
           05  WS-PARAMETRO-ENCONTRADO   PIC  X(01)  VALUE 'N'.         03240000
               88  WS-88-ENCONTRADO-OK               VALUE 'S'.         03250000
               88  WS-88-ENCONTRADO-NOOK             VALUE 'N'.         03260000
                                                                        03270000
           05  WS-LAST-RETRY             PIC  X(01)  VALUE 'N'.         03280000
               88  WS-NO-LAST-RETRY                  VALUE 'N'.         03290000
               88  WS-SI-LAST-RETRY                  VALUE 'S'.         03300000
           05  WS-BLQ-VP28               PIC  X(01)  VALUE  SPACES.     00160022
               88  WS-BLQ-VP28-ERR                   VALUE  'G', 'F',   00160022
                                           'A', 'M', 'O', 'U', 'Y'.     00160022
                                                                        00160022
       01  WS-CODIGOS-ERRORES.                                          03310000
           05  WS-COD-E-OBT-CONEXION      PIC  X(02) VALUE '01'.        03320000
           05  WS-COD-E-OBT-SYSID         PIC  X(02) VALUE '02'.        03330000
           05  WS-COD-E-OBTIENE-FECHA     PIC  X(02) VALUE '03'.        03340000
           05  WS-COD-E-FORMATTIME        PIC  X(02) VALUE '04'.        03350000
           05  WS-COD-E-CARGA-TSIS        PIC  X(02) VALUE '05'.        03360000
           05  WS-COD-E-COMMAREA          PIC  X(02) VALUE '06'.        03370000
           05  WS-COD-E-CANAL-INV         PIC  X(02) VALUE '07'.        03380000
           05  WS-COD-E-TIP-PAGO          PIC  X(02) VALUE '08'.        03390000
           05  WS-COD-E-COD-MON           PIC  X(02) VALUE '09'.        03400000
           05  WS-COD-E-TIP-TRN           PIC  X(02) VALUE '10'.        03410000
           05  WS-COD-E-INTERNO-BCTITP8   PIC  X(02) VALUE '11'.        03420000
           05  WS-COD-E-ACTUALIZ          PIC  X(02) VALUE '12'.        03430000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(02) VALUE '13'.        03440000
           05  WS-COD-E-READ-UBIGEO       PIC  X(02) VALUE '14'.        03450000
           05  WS-COD-E-TRAMA-CONS        PIC  X(02) VALUE '15'.        03460000
           05  WS-COD-E-CONS-INCOR        PIC  X(02) VALUE '16'.        03470000
           05  WS-COD-E-TARIFA-NO-FOUND   PIC  X(02) VALUE '17'.        03480000
           05  WS-COD-E-RANGO-NO-FOUND    PIC  X(02) VALUE '18'.        03490000
           05  WS-COD-E-RANGO-MENOR       PIC  X(02) VALUE '19'.        03500000
           05  WS-COD-E-ACCESO-MAESTRO    PIC  X(02) VALUE '20'.        03510000
           05  WS-COD-E-DUP-RECORD        PIC  X(02) VALUE '21'.        03520000
           05  WS-COD-E-ARCHIVO-LOG       PIC  X(02) VALUE '22'.        03530000
           05  WS-COD-E-LINK-GRAL         PIC  X(02) VALUE '23'.        03540000
           05  WS-COD-E-NEXT-PROC         PIC  X(02) VALUE '24'.        03550000
           05  WS-COD-E-ASKTIME           PIC  X(02) VALUE '25'.        03560000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(02) VALUE '26'.        03570000
           05  WS-COD-E-INTERNO-BCTITP80  PIC  X(02) VALUE '27'.        03580000
           05  WS-COD-E-IMPORTE-SUP       PIC  X(02) VALUE '28'.        03590000
           05  WS-COD-E-RUT-BCRGTP05      PIC  X(02) VALUE '29'.        03600000
           05  WS-COD-E-ACCESS-FILE       PIC  X(02) VALUE '30'.        03610000
                                                                        03620000
       01  WS-DESCRIPCION-ERRORES.                                      03630000
           05  WS-88-ERROR-OBT-CONEXION  PIC  X(80) VALUE               03640000
               'ERROR EN ACCESO ARCHIVO LOG                           '.03650000
           05  WS-88-ERROR-OBT-SYSID     PIC  X(80) VALUE               03660000
               'ERROR EN INVOKINGPROG                                 '.03670000
           05  WS-88-ERROR-OBTIENE-FECHA PIC  X(80) VALUE               03680000
               'ERROR AL RECUPERAR LA FECHA DEL SISTEMA               '.03690000
           05  WS-88-ERROR-FORMATTIME    PIC  X(80) VALUE               03700000
               'ERROR EN FORMATTIME                                   '.03710000
           05  WS-88-ERROR-CARGA-TSIS    PIC  X(80) VALUE               03720000
               'ERROR AL CARGAR LA TABLA DEL SISTEMA                  '.03730000
           05  WS-88-ERROR-COMMAREA      PIC  X(80) VALUE               03740000
               'ERROR AL OBTENER CONEXION                             '.03750000
           05  WS-88-ERROR-CANAL-INV     PIC  X(80) VALUE               03760000
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.03770000
           05  WS-88-ERROR-TIP-PAGO      PIC  X(80) VALUE               03780000
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.03790000
           05  WS-88-ERROR-COD-MON       PIC  X(80) VALUE               03800000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03810000
           05  WS-88-ERROR-TIP-TRN       PIC  X(80) VALUE               03820000
               'NEXT DAY EN PROCESO                                   '.03830000
           05  WS-ERROR-INTERNO-BCTITP80 PIC  X(80) VALUE               03840000
               'NEXT DAY INICIO                                       '.03850000
           05  WS-88-ERROR-ACTUALIZ      PIC  X(80) VALUE               03860000
               'ERROR AL OBTENER COUNTER                              '.03870000
           05  WS-COD-E-REGISTRO-NO-FOUND PIC  X(80) VALUE              03880000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.03890000
           05  WS-88-ERROR-TRAMA-CONS    PIC  X(80) VALUE               03900000
               'ERROR AL RECIBIR LA TRAMA VIA LINK                    '.03910000
           05  WS-88-ERROR-CONS-INCOR    PIC  X(80) VALUE               03920000
               'ERROR AL RECIBIR LA TRAMA VIA START                   '.03930000
           05  WS-88-ERROR-RANGO-NO-FOUND PIC  X(80) VALUE              03940000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.03950000
           05  WS-88-ERROR-RANGO-MENOR   PIC  X(80) VALUE               03960000
               'NEXT DAY EN PROCESO                                   '.03970000
           05  WS-88-ERROR-ACCESO-MAESTRO PIC  X(80) VALUE              03980000
               'NEXT DAY INICIO                                       '.03990000
           05  WS-88-ERROR-DUP-RECORD    PIC  X(80) VALUE               04000000
               'ERROR AL OBTENER COUNTER                              '.04010000
           05  WS-88-ERROR-ARCHIVO-LOG    PIC  X(80) VALUE              04020000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.04030000
           05  WS-88-ERROR-LINK-GRAL      PIC  X(80) VALUE              04040000
               'ERROR AL RECIBIR LA TRAMA VIA OTROS                   '.04050000
           05  WS-88-ERROR-NEXT-PROC     PIC  X(80) VALUE               04060000
               'NEXT DAY EN PROCESO                                   '.04070000
           05  WS-88-ERROR-ASKTIME        PIC  X(80) VALUE              04080000
               'NEXT DAY INICIO                                       '.04090000
           05  WS-88-ERROR-REGISTRO-NO-FOUND PIC X(80) VALUE            04100000
               'ERROR AL OBTENER COUNTER                              '.04110000
           05  WS-88-ERROR-READ-UBIGEO    PIC  X(80) VALUE              04120000
               'NO ENCONTRADO EN EL ARCHIVO DE PARAMETROS             '.04130000
           05  WS-88-ERROR-IMPORTE-SUP    PIC  X(80) VALUE              04140000
               'IMPORTE SUPERIOR                                      '.04150000
           05  WS-88-ERROR-RUTINA-BCRGTP05 PIC  X(80) VALUE             04160000
               'ERROR EN RUTINA BCRGTP05                              '.04170000
           05  WS-88-ERROR-EN-MONEDA-NOSOL PIC  X(44) VALUE             04180000
               'ERROR EN MONEDA NO ES SOLES                '.           04190000
           05  WS-88-ERROR-EN-MONEDA-NODOL PIC  X(44) VALUE             04200000
               'ERROR EN MONEDA NO ES DOLAR                '.           04210000
           05  WS-88-ERROR-ACCESS-FILE      PIC X(80) VALUE             04220000
               'ERROR AL GRABAR EN MAESTRO DE TRANSACCIONES           '.04230000
           05  WS-88-ERROR-ACCESS-LOG       PIC X(80) VALUE             04240000
               'ERROR AL GRABAR EN ARCHIVO LOG                        '.04250000
      ******************************************************************04260000
      *                TABLA DE CODIGOS DE RESPUESTA                   *04270000
      ******************************************************************04280000
       01  WS-VARIABLES-ERROR.                                          04472000
           05  WS-VARMSG-FUN             PIC  X(20)  VALUE SPACES.      04473000
           05  WS-VARMSG-RSO             PIC  X(20)  VALUE SPACES.      04474000
           05  WS-VARMSG-ARG             PIC  X(20)  VALUE SPACES.      04475000
           05  WS-VARMSG-TXT             PIC  X(30)  VALUE SPACES.      04476000
           05  WS-VARMSG-OPE             PIC  X(20)  VALUE SPACES.      04477000
      *                                                                 04480000
       01  WS-COD-ORIG.                                                 04490000
           10  WS-COD-RESP              PIC X(04).                      04500000
           10  FILLER                   PIC X(01) VALUE SPACES.         04510000
           10  WS-ORI-RESP              PIC X(03).                      04520000
      *                                                                 04530000
       01  WS-VALIDO           PIC X(1)  VALUE SPACES.                  04540000
           88  WS-VALIDO-NUM      VALUE '0' '1' '2' '3' '4'             04550000
               '5' '6' '7' '8' '9'.                                     04560000
           88  WS-VALIDO-ALF      VALUE 'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 04570000
                                        'I' 'J' 'K' 'L' 'M'             04580000
                                        'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 04590000
                                        'V' 'W' 'X' 'Y' 'Z'.            04600000
                                                                        04610000
       01 WS-NROCLI-CONSIS-WORK      PIC X(08).                         04620000
       01 WS-NROCLI-CONSIS-WORK1     PIC X(08).                         04630000
      ** OPTIMIZACION CARACTERES ESPECIALES                             04631000
       01 WS-FINDREPLACE  PIC X(99) VALUE '‚ƒ‡·„ÂÁÒ¢ÈÍÎËÌÓÔÏﬂ¨¬ƒ¿¡√≈«¯… 00069579
      -           'À»ÕŒœÃ`ÿ˝Ê∆~›Æ^£•©ÙÚÛı˚¸˘˙ˇ‘÷“”’€‹Ÿ⁄!$;<>|¶%_?:="[]{}04633000
      -           '\—&@∞#()ø°*,.-/+'.                                   00069579
       01 WS-REPLACE      PIC X(99) VALUE 'AAAAAA N EEEEIIII  AAAAAA  EE00069579
      -           'EEIIII            oooouuuu OOOOOUUUU                 04636000
      -           ' NY              '.                                  00069579
      *                                                                 04640000
      ******************************************************************04650000
      *                COPYBOOKS Y COMMAREAS DE TRABAJO                *04660000
      ******************************************************************04670000
                                                                        04680000
      *--------------  COMMAREA PARA PROGRAMAS DE RECEPTOR              00160022
       COPY BCTICA02.                                                   00160022
                                                                        00160022
      *--------------  COPY DE COMUNICACION PARA RUTINA DE MENSAJES     04680100
       COPY BCTICA15.                                                   04680200
                                                                        04680300
      *--------------  MANTENIMIENTO ARCHIVO DE PARAMETROS              04681000
       COPY BCTICA80.                                                   04682000
                                                                        04683000
      *--------------  COPY DE ARCHIVO LOG                              04710000
       COPY BCTICF07.                                                   04720000
                                                                        04721000
      *--------------  COPY DE ARCHIVO MAESTRO DE TRANSACCIONES         04730000
       COPY BCTICF06.                                                   04740000
                                                                        04741000
      *--------------  COPY DE ARCHIVO DE PARAMETROS                    04750000
       COPY BCTICF01.                                                   04760000
                                                                        04760100
      *--------------  COPY TRAMA INPUT/OUTPUT NOVATRONICS              04761000
       COPY BCTITR02.                                                   04762000
                                                                        04763000
      *-------------- COPY MQSERIES/HOST PARA CONSULTAS IMPACS          04770000
       COPY BCIMYR8S.                                                   04780000
                                                                        04781000
      *-------------- COPY MQSERIES/HOST PARA CONSULTAS SAVING STDA     04790000
       COPY BCSTYR80.                                                   04800000
      *-------------- COPY RUTINA DE ACCESO AL ARCHIVO DE PAR·METROS DE 04810000
       COPY BCRGCA05.                                                   04820000
      *-------------- COPY RUTINA DE ASIGNACIÛN DIN·MICA DE USUARIO Y TE04830000
       COPY BCRGCA04.                                                   04840000
      *-------------- COPY RUTINA SGCPPDGC-ONLINE/SGCPGDGC-BATCH  PARA A04850000
       COPY SGCWGDGC.                                                   04860000
      *-------------- COPY DE SERVICIO VP28 DE VPLUS                    04870000
       COPY BCVPAR05.                                                   04880000
      *-------------- COPY ESTRUCTURA DE HEADER ESTANDAR                04890000
       COPY BCRGCA10.                                                   04900000
                                                                        04910000
      *                                                                 04920000
      *****************                                                 04930000
       LINKAGE SECTION.                                                 04940000
      *****************                                                 04950000
      *01  DFHCOMMAREA                 PIC  X(1540).                    00160022
       01  DFHCOMMAREA                 PIC  X(2000).                    00160022
                                                                        04961000
                                                                        04962000
      *--------------  TABLA DEL SISTEMA TTIB ONLINE                    04962100
       COPY BCTICW03.                                                   04962200
                                                                        04963000
      ********************                                              04970000
       PROCEDURE DIVISION.                                              04980000
      ********************                                              04990000
                                                                        05000000
           PERFORM  1000-INICIO                                         05010000
                                                                        05020000
           IF  WS-NO-EXISTE-ERROR                                       05030000
               PERFORM  4000-PROCESO                                    05040000
           END-IF                                                       05050000
           PERFORM  9000-TERMINAR                                       05060000
           .                                                            05070000
      ************************ FIN DE PROCEDURE DIVISION                05070100
      *************                                                     05071000
       1000-INICIO.                                                     05080000
      *************                                                     05081000
      ******************************************************************05090000
      * RECIBE COMMAREA                                                *05100000
      ******************************************************************05101000
                                                                        05120000
           EXEC  CICS                                                   05130000
               HANDLE ABEND                                             05140000
                      LABEL (9999-MANEJO-EXCEPCIONES)                   05150000
           END-EXEC                                                     05160000
                                                                        05170000
           INITIALIZE  TI-CF06-REG-TRANS                                05171000
                       REPLACING  ALPHANUMERIC DATA BY SPACES           05172000
                                       NUMERIC DATA BY ZEROS            05173000
                                                                        05174000
           PERFORM  1005-OBTIENE-SYSID                                  05180000
           PERFORM  1020-OBTIENE-FECHA-HORA-INICIO                      05190000
           PERFORM  1100-RECIBE-COMMAREA                                05200000
           PERFORM  1200-CARGA-TABLA-SIST-TTIB                          05201000
           PERFORM  1300-CARGA-TABLA-MAESTRO                            05210000
           PERFORM  1400-INVOCA-RUT-BCRGTP05                            05220000
           .                                                            05222000
      ************************ FIN DE 1000-INICIO                       05223000
      ********************                                              05230000
       1005-OBTIENE-SYSID.                                              05240000
      ********************                                              05241000
      ******************************************************************05250000
      * OBTIENE EL SYSID DEL CICS DONDE SE EJECUTA EL PROGRAMA         *05260000
      ******************************************************************05261000
                                                                        05280000
           EXEC  CICS  ASSIGN                                           05290000
                 INVOKINGPROG (WS-PROG-CALLER)                          05300000
                    STARTCODE (WS-TIPO-CONEX)                           05310000
                        SYSID (WS-SYSID-LOC)                            05320000
                       USERID (WS-USUARIO)                              05330000
                         RESP (WS-RESP)                                 05340000
                        RESP2 (WS-RESP2)                                05350000
           END-EXEC.                                                    05360000
      *                                                                 05370000
           EVALUATE WS-RESP                                             05380000
             WHEN DFHRESP(NORMAL)                                       05390000
              CONTINUE                                                  05400000
             WHEN OTHER                                                 05410000
               SET  WS-SI-EXISTE-ERROR          TO TRUE                 05420000
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 05430000
               MOVE WS-COD-E-OBT-SYSID          TO WS-CODMSG            05440000
               MOVE WS-88-ERROR-OBT-SYSID       TO WS-TXTMSG            05450000
               PERFORM  6000-FINAL                                      05460000
           END-EVALUATE                                                 05470000
           .                                                            05471000
      ************************ FIN DE 1005-OBTIENE-SYSID                05480000
      ********************************                                  05481000
       1020-OBTIENE-FECHA-HORA-INICIO.                                  05490000
      ********************************                                  05491000
      ******************************************************************05500000
      * RECUPERAMOS LA FECHA Y HORA DE INICIO  DESDE EL CICS.          *05510000
      ******************************************************************05520000
                                                                        05530000
           EXEC  CICS  ASKTIME                                          05540000
                       ABSTIME (WS-ABSTIME)                             05550000
                       RESP (WS-RESP)                                   05560000
                       RESP2 (WS-RESP2)                                 05570000
           END-EXEC                                                     05580000
      *                                                                 05590000
           EVALUATE WS-RESP                                             05600000
              WHEN DFHRESP(NORMAL)                                      05610000
                CONTINUE                                                05620000
              WHEN OTHER                                                05630000
                SET  WS-SI-EXISTE-ERROR          TO TRUE                05640000
                SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                05650000
                MOVE WS-COD-E-OBTIENE-FECHA      TO WS-CODMSG           05660000
                MOVE WS-88-ERROR-OBTIENE-FECHA   TO WS-TXTMSG           05670000
                PERFORM 6000-FINAL                                      05680000
           END-EVALUATE                                                 05690000
      *                                                                 05700000
           EXEC  CICS  FORMATTIME                                       05710000
                        ABSTIME (WS-ABSTIME)                            05720000
                       YYYYMMDD (WS-FECHA-INI)                          05730000
                           TIME (WS-HORA-INI)                           05740000
                       TIMESEP                                          05750000
                       RESP     (WS-RESP)                               05760000
                       RESP2    (WS-RESP2)                              05770000
           END-EXEC                                                     05780000
      *                                                                 05790000
           EVALUATE WS-RESP                                             05800000
              WHEN DFHRESP(NORMAL)                                      05810000
                   CONTINUE                                             05820000
              WHEN OTHER                                                05830000
                   SET  WS-SI-EXISTE-ERROR          TO TRUE             05840000
                   SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE             05850000
                   MOVE WS-COD-E-FORMATTIME         TO WS-CODMSG        05860000
                   MOVE WS-88-ERROR-FORMATTIME      TO WS-TXTMSG        05870000
                   PERFORM 6000-FINAL                                   05880000
           END-EVALUATE                                                 05890000
           .                                                            05890100
      ************************ FIN DE 1005-OBTIENE-SYSID                05891000
      **********************                                            05900000
       1100-RECIBE-COMMAREA.                                            05910000
      **********************                                            05911000
      ******************************************************************05920000
      * IDENTIFICA A PARTIR DE LOS RECURSOS CICS EL TIPO DE LLAMADA A  *05930000
      * NUESTRO PROGRAMA Y RECIBE LA TRAMA DE ENTRADA.                 *05940000
      ******************************************************************05950000
                                                                        05960000
           IF  EIBCALEN  GREATER  ZEROS                                 05970000
               MOVE DFHCOMMAREA            TO TI-CA02-AREA-COMUNICACION 00160022
               MOVE TI-CA02-REG-TRANS-DATA TO TI-TR02-I-TRAMA           00160022
                                                                        00160022
               MOVE TI-CA02-FILE-NAME-MAESTRO                           00160022
                                           TO WS-FILE-NM-MAESTRO        00160022
               MOVE TI-CA02-FILE-NAME-MAESTRO-ALT                       00160022
                                           TO WS-FILE-NM-MAESTRO-ALT    00160022
               MOVE TI-CA02-FILE-NAME-MAESTRO-ALT2                      00160022
                                           TO WS-FILE-NM-MAESTRO-ALT2   00160022
               MOVE TI-CA02-FILE-NAME-EVEN-LOG                          00160022
                                           TO WS-FILE-NM-EVEN-LOG       00160022
                                                                        00160022
           ELSE                                                         05990000
               SET  WS-SI-EXISTE-ERROR          TO TRUE                 06000000
               SET  WS-CODTIP-88-ERROR-RECURSOS TO TRUE                 06010000
               MOVE WS-COD-E-COMMAREA           TO WS-CODMSG            06020000
               MOVE WS-88-ERROR-COMMAREA        TO WS-TXTMSG            06030000
               PERFORM 6000-FINAL                                       06040000
           END-IF                                                       06050000
           .                                                            06051000
      ************************ FIN DE 1100-RECIBE-COMMAREA              06052000
      ****************************                                      06061000
       1200-CARGA-TABLA-SIST-TTIB.                                      06062000
      ****************************                                      06063000
      ******************************************************************06064000
      * OBTIENE EL SYSID DE LA REGION CICS DONDE SE EJECUTA EL PRGM. Y *06065000
      * CARGA  LA TABLA DEL SYSTEMA TTIB                               *06066000
      ******************************************************************06067000
                                                                        06068000
           EXEC  CICS  LOAD                                             06069000
                    PROGRAM (WS-TSIS-TTIB)                              06069100
                        SET (WS-PTR-TSIS)                               06069200
                       RESP (WS-RESP)                                   06069300
                      RESP2 (WS-RESP2)                                  06069400
           END-EXEC                                                     06069500
                                                                        06069600
           IF  WS-RESP EQUAL DFHRESP(NORMAL)                            06069700
               SET  ADDRESS OF TI-CW03-REG-TABLA-SISTEMA                06069800
                                           TO WS-PTR-TSIS               06069900
           ELSE                                                         06070000
      *        OBTENER MENSAJE PARA CCE                                 06070100
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06070200
                                                                        06070300
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      06070400
               SET  TI-CF06-88-RECH        TO TRUE                      06070500
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     06070600
                                          WS-TEMP-XX                    06070700
                                          WS-CODMSG-ESTRUCTURA(1: 2)    06070800
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     06070900
                                          WS-CODMSG-ESTRUCTURA(3: 4)    06071000
               MOVE WS-CT-1021N        TO WS-CT-NUMER                   06071100
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      06071200
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             06071300
                                                                        06071400
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     06071500
               PERFORM 1340-ACTUALIZA-COMAREA                           06071600
                                                                        06071700
      *        OBTENER MENSAJE INTERNO                                  06071800
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      06071900
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      06072000
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    06072100
                                              WS-CODMSG-ESTRUCTURA      06072200
                                              WS-COD-ERROR-07           06072300
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            06072400
                                              WS-PROGRAM                06072500
               MOVE 'LOAD'                 TO WS-VARMSG-FUN             06072600
               MOVE WS-TSIS-TTIB           TO WS-VARMSG-RSO             06072700
                                                                        06072800
               PERFORM 6100-OBTENER-MENSAJE                             06072900
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            06073000
                                              WS-MENSAJE-TXT-EVE        06073100
                                                                        06073200
               PERFORM 1360-GRABAR-LOG-EVENTOS                          06073300
               PERFORM 6000-FINAL                                       06073400
           END-IF                                                       06073500
           .                                                            06073600
      ************************ FIN DE 1200-CARGA-TABLA-SIST-TTIB        06073700
      **************************                                        06073800
       1300-CARGA-TABLA-MAESTRO.                                        06074000
      **************************                                        06075000
      *                                                                 06090000
           SET  TI-CF06-88-COD-PROCESO-CON TO TRUE                      06100000
           SET  TI-CF06-88-TIPO-ROL-RECEPT TO TRUE                      06110000
           SET  TI-CF06-88-AFECT-CNTBL-NO  TO TRUE                      00160022
           MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-TRACE-ADQUIRIENTE 06120000
           MOVE TI-TR02-CANAL              TO TI-CF06-CANAL-CCE         06130000
           MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF06-BIN-ADQUIRIENTE   06140000
           MOVE TI-TR02-TERMINAL-ID        TO TI-CF06-TERMINAL-ID       06150000
           MOVE TI-TR02-DATE-LOCAL         TO TI-CF06-FECHA-TRANS       06160000
           MOVE TI-TR02-TIME-LOCAL         TO TI-CF06-HORA-TRANS        06170000
           MOVE WS-FEINI-CICS              TO TI-CF06-FECHA-PROCESO     06220000
           MOVE WS-HOINI-CICS              TO TI-CF06-HORA-PROCESO      06230000
           MOVE TI-TR02-ENTIDAD-ORIGEN(2:3)TO TI-CF06-CODIGO-BCO-EMI    06231000
           MOVE WS-CT-TI                   TO TI-CF06-CANAL-BCP         06240000
           MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF06-NRO-OPERACION-CNL 06250000
           SET  TI-CF06-88-PEND            TO TRUE                      06260000
           SET  TI-CF06-88-NO-REENV        TO TRUE                      06270000
           MOVE SPACES                     TO TI-CF06-NUM-LIQ-I         06280000
           SET  TI-CF06-88-TIP-PROC-LINEA  TO TRUE                      06290000
           MOVE TI-TR02-FECHA-HORA-PROC    TO TI-CF06-FECHA-PROCESO-CCE 06300000
           MOVE TI-TR02-FECHA-PROCESO      TO TI-CF06-FECHA-PROCE-CCE   00160022
           MOVE TI-TR02-NRO-REFERENCIA     TO TI-CF06-NRO-REFERENCIA    06310000
           MOVE TI-TR02-AUTORIZAT-ID-RESP  TO TI-CF06-AUTORIZAT-ID-RESP 06320000
           MOVE SPACES                     TO TI-CF06-RESPONSE-CODE-CCE 06330000
           MOVE TI-TR02-COMERCIO           TO TI-CF06-COMERCIO          06340000
           MOVE TI-TR02-CARD-ACEPTOR-LOCA  TO TI-CF06-CARD-ACEPTOR-LOCA 06350000
           MOVE SPACES                     TO TI-CF06-COD-RESP-AMPLIADO 06360000
           MOVE SPACES                     TO TI-CF06-ORIGEN-RESPUESTA  06370000
           MOVE SPACES                     TO TI-CF06-MENSAJE-RESPUESTA 06380000
           MOVE TI-TR02-RUTEO              TO TI-CF06-ENT-BEN           06390000
           MOVE TI-TR02-COD-APLICACION     TO TI-CF06-COD-APLICACION    06400000
           MOVE TI-TR02-TIPO-SESION        TO TI-CF06-TIPO-SESION       06410000
           PERFORM 4150-BUSCAR-MON                                      06420000
           PERFORM 4200-BUSCAR-CAUSAL                                   06440000
           MOVE SPACES                     TO TI-CF06-TIP-PAGO          06450000
           MOVE TI-TR02-IMPORTE            TO WS-TR02-IMPORTE-R         06460000
           COMPUTE WS-TR02-IMPORTE-R = WS-TR02-IMPORTE-R / 100          06470000
           END-COMPUTE                                                  06480000
           MOVE WS-TR02-IMPORTE-R          TO TI-CF06-IMPORTE           06490000
                                                                        06490100
           IF TI-TR02-ID-TRANS-CCE-ONLINE EQUAL TO SPACES               06491000
              STRING TI-CF06-COD-PROCESO  TI-CF06-TIPO-ROL              06492000
                     TI-CF06-FECHA-PROCESO   TI-CF06-AUTORIZAT-ID-RESP  06493000
              DELIMITED BY SIZE INTO TI-CF06-ID-TRANS-CCE-ONLINE        06494000
           ELSE                                                         06495000
              MOVE TI-TR02-ID-TRANS-CCE-ONLINE TO                       06496000
                                          TI-CF06-ID-TRANS-CCE-ONLINE   06497000
           END-IF                                                       06498000
                                                                        06499000
           MOVE TI-TR02-ID-TRANS-CCE-ONL-OR                             06520000
                                         TO TI-CF06-ID-TRANS-CCE-ONL-ORG06530000
           MOVE TI-TR02-ID-SESION-APLICA   TO TI-CF06-ID-SESION-APLICA  06540000
           MOVE TI-TR02-CONCEPT-COBRO-TARI TO TI-CF06-CONCEPT-COBRO-TARI06550000
           MOVE TI-TR02-CODIGO-TARIFA      TO TI-CF06-CODIGO-TARIFA     06560000
      *                                                                 06570000
           MOVE ZEROS                      TO TI-CF06-IMPORTE-COMISION  06580000
      *                                                                 06650000
           MOVE TI-TR02-IMPORTE-COMISION   TO WS-TR02-IMPORTE-COMI-R    06651000
                                                                        06652000
           COMPUTE WS-TR02-IMPORTE-COMI-R = WS-TR02-IMPORTE-COMI-R / 10006653000
           END-COMPUTE                                                  06654000
                                                                        06655000
           IF  TI-TR02-SIGNO-COMISION = '-'                             06656000
               COMPUTE TI-CF06-IMP-COM-INTERB =                         06657000
                       WS-TR02-IMPORTE-COMI-R * -1                      06658000
               END-COMPUTE                                              06659000
                                                                        06659100
           ELSE                                                         06659200
               MOVE WS-TR02-IMPORTE-COMI-R TO TI-CF06-IMP-COM-INTERB    06659300
                                                                        06659400
           END-IF                                                       06659500
                                                                        06659600
           MOVE ' '                        TO TI-CF06-IMP-TOT(1:01)     06660000
           MOVE WS-MONTO-20(2:14)          TO TI-CF06-IMP-TOT(2:14)     06670000
           MOVE '.'                        TO TI-CF06-IMP-TOT(16:1)     06680000
           MOVE WS-MONTO-20(17:4)          TO TI-CF06-IMP-TOT(17:4)     06690000
           MOVE TI-TR02-CRITERIO-APLICACION TO TI-CF06-CRITERIO-APLICA  06700000
           MOVE TI-TR02-REF-TRANSFERENCIA TO TI-CF06-REF-TRANSFERENCIA  06710000
           MOVE TI-TR02-INDICADOR-PAG-HAB TO TI-CF06-INDICADOR-PAG-HAB  06720000
           MOVE TI-TR02-MES-PAGO          TO TI-CF06-MES-PAGO           06730000
           MOVE TI-TR02-ANIO-PAGO         TO TI-CF06-ANIO-PAGO          06740000
           MOVE TI-TR02-IMPORT-SUELDO-BRUTO                             06750000
                                          TO TI-CF06-IMPORT-SUELDO-BRUTO06760000
           MOVE TI-TR02-NRO-CORTE         TO TI-CF06-NRO-CORTE          06770000
           MOVE TI-TR02-ID-ALERTA         TO TI-CF06-ID-ALERTA          06780000
           MOVE TI-TR02-ENTIDAD-ORIGEN    TO TI-CF06-ENTIDAD-ORIGEN     06790000
           MOVE TI-TR02-CCI-CLI-ORIGINANTE TO TI-CF06-CCI-CLI-ORIG      06800000
           MOVE TI-TR02-TIPO-PERSONA      TO TI-CF06-TIPO-PERSONA       06810000
           MOVE SPACES                    TO TI-CF06-IDC-ORI            06820000
           MOVE TI-TR02-TIP-DOC-CLI-ORIG  TO TI-CF06-TIP-DOC-CLI-ORIG   06830000
           MOVE TI-TR02-NRO-DOC-CLI-ORIG  TO TI-CF06-NRO-DOC-CLI-ORIG   06840000
           MOVE TI-TR02-APE-PAT-CLI-ORIG  TO TI-CF06-APE-PAT-CLI-ORIG   06850000
           MOVE TI-TR02-APE-MAT-CLI-ORIG  TO TI-CF06-APE-MAT-CLI-ORIG   06860000
           MOVE TI-TR02-NOMBRE-CLI-ORIG   TO TI-CF06-NOMBRE-CLI-ORIG    06870000
           MOVE TI-TR02-DIRECC-CLI-ORIG   TO TI-CF06-DIRECC-CLI-ORIG    06880000
           MOVE TI-TR02-NRO-CEL-CLI-ORIG  TO TI-CF06-NRO-CEL-CLI-ORIG   06890000
           MOVE TI-TR02-ENTIDAD-DESTINO   TO TI-CF06-ENTIDAD-DESTINO    06900000
           MOVE TI-TR02-CCI-CLI-BENEFICIA TO TI-CF06-CCI-CLI-BENEFICIA  06910000
           MOVE TI-TR02-COD-TARJETA-CRED  TO TI-CF06-COD-TARJETA-CRED   06920000
           MOVE SPACES                    TO TI-CF06-IDC-BEN            06930000
           MOVE TI-TR02-TIP-DOC-CLI-BENE  TO TI-CF06-TIP-DOC-CLI-BENE   06940000
           MOVE TI-TR02-NRO-DOC-CLI-BENE  TO TI-CF06-NRO-DOC-CLI-BENE   06950000
           MOVE SPACES                    TO TI-CF06-APE-PAT-CLI-BENE   06960000
           MOVE SPACES                    TO TI-CF06-APE-MAT-CLI-BENE   06970000
           MOVE SPACES                    TO TI-CF06-NOMBRE-CLI-BENE    06980000
           MOVE TI-TR02-DIRECC-CLI-BENE   TO TI-CF06-DIRECC-CLI-BENE    06990000
           MOVE TI-TR02-TELEF-CLI-BENE    TO TI-CF06-TELEF-CLI-BENE     07000000
           MOVE TI-TR02-NRO-CEL-CLI-BENE  TO TI-CF06-NRO-CEL-CLI-BENE   07010000
           MOVE TI-TR02-INDI-MISMO-CLIENTE   TO                         07020000
                                             TI-CF06-INDI-MISMO-CLIENTE 07030000
           MOVE '000'                     TO TI-CF06-SUCURSAL-ORIG-OPE  00069579
           MOVE '000'                     TO TI-CF06-AGENCIA-ORIG-OPE   00069579
           .                                                            07030100
      ************************ FIN DE 1300-CARGA-TABLA-MAESTRO          07031000
      **************************                                        07040000
       1400-INVOCA-RUT-BCRGTP05.                                        07050000
      **************************                                        07051000
      ******************************************************************07060000
      * INVOCA PROGRAMA BCRGTP05 -                                     *07070000
      ******************************************************************07071000
           SET RG-CA05-I-AMB-ACT    TO TRUE                             07090000
           SET RG-CA05-I-1RA-CON-SI TO TRUE.                            07100000
                                                                        07110000
           EXEC CICS LINK PROGRAM  (WS-RTN-BCRGTP05)                    07120000
                          COMMAREA (RG-CA05-COMMAREA)                   07130000
                          LENGTH   (LENGTH OF RG-CA05-COMMAREA)         07140000
                          RESP     (WS-RESP)                            07150000
           END-EXEC.                                                    07160000
      *                                                                 07170000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        07240000
      *        OBTENER MENSAJE PARA CCE                                 07241000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      07242000
                                                                        07243000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      07244000
               SET  TI-CF06-88-RECH        TO TRUE                      07250000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 07260000
                                              WS-TEMP-XX                07260100
                                              WS-CODMSG-ESTRUCTURA(1: 2)07260200
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 07261000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07262000
               MOVE WS-CT-1021N            TO WS-CT-NUMER               07263000
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  07270000
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             07271000
                                                                        07272000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 07280000
               PERFORM 1340-ACTUALIZA-COMAREA                           07300000
                                                                        07301000
      *        OBTENER MENSAJE INTERNO                                  07301100
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      07301200
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      07301300
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    07301400
                                              WS-CODMSG-ESTRUCTURA      07301600
                                              WS-COD-ERROR-07           07301700
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            07301800
                                              WS-PROGRAM                07301900
               MOVE 'LINK'                 TO WS-VARMSG-FUN             07302000
               MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             07302100
                                                                        07302200
               PERFORM 6100-OBTENER-MENSAJE                             07303000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            07304000
                                              WS-MENSAJE-TXT-EVE        07305000
                                                                        07306000
               PERFORM 1360-GRABAR-LOG-EVENTOS                          07310000
               PERFORM 6000-FINAL                                       07320000
           ELSE                                                         07330000
               IF  RG-CA05-O-RET-NRO = WS-CT-0000                       07340000
                   CONTINUE                                             07350000
               ELSE                                                     07360000
      *            OBTENER MENSAJE PARA CCE                             07451000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  07452000
                                                                        07453000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  07454000
                   SET  TI-CF06-88-RECH        TO TRUE                  07455000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 07456000
                                              WS-TEMP-XX                07457000
                                              WS-CODMSG-ESTRUCTURA(1: 2)07458000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 07459000
                                              WS-CODMSG-ESTRUCTURA(3: 4)07459100
                   MOVE WS-CT-1021N        TO WS-CT-NUMER               07459200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  07459300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         07459400
                                                                        07459500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 07459600
                                                                        07459800
      *            OBTENER MENSAJE INTERNO                              07459900
                   MOVE RG-CA05-O-RETORNO  TO TI-CF06-CODMSG-ESTRUCT    07460200
                                              WS-COD-ERROR-07           07460300
                   MOVE WS-RTN-BCRGTP05    TO TI-CF06-PRGNOM            07460400
                                              WS-PROGRAM                07460500
                   MOVE RG-CA05-O-MSJ-RET  TO TI-CF06-TXTMSG            07460900
                                              WS-MENSAJE-TXT-EVE        07461000
                                                                        07461100
                   PERFORM 1340-ACTUALIZA-COMAREA                       07461200
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      07461300
                   PERFORM 6000-FINAL                                   07461400
               END-IF                                                   07462000
           END-IF                                                       07470000
           .                                                            07470100
      ************************ FIN DE 1400-INVOCA-RUT-BCRGTP05          07471000
      ************************                                          07481000
       1340-ACTUALIZA-COMAREA.                                          07490000
      ************************                                          07500000
      ******************************************************************07501000
      *ACTUALIZA COMMAREA CON CAMPO ERRADO                              07510000
      ******************************************************************07520000
                                                                        00160022
           MOVE WS-TEMP-XX             TO TI-TR02-RESPONSE-CODE-CCE     07530000
           MOVE WS-CT-NUMER            TO TI-TR02-COD-RESP-AMPLIADO     07531000
           MOVE WS-CT-001              TO TI-TR02-ORIGEN-RESPUESTA      07540000
           MOVE WS-MENSAJE-TXT         TO TI-TR02-MENSAJE-RESPUESTA     07550000
      *    MOVE TI-TR02-I-TRAMA        TO DFHCOMMAREA                   00160022
           MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
           MOVE TI-CA02-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
           .                                                            07561000
      ************************ FIN DE 1340-ACTUALIZA-COMAREA            07570000
      *************************                                         07571000
       1360-GRABAR-LOG-EVENTOS.                                         07580000
      *************************                                         07590000
      ******************************************************************07591000
      * GRABAR MOTIVO DE ERROR EN EL LOG DE EVENTO                      07600000
      ******************************************************************07601000
           INITIALIZE  TI-CF07-REG-TRANS                                07620000
                       REPLACING  ALPHANUMERIC DATA BY SPACES           07630000
                                  NUMERIC DATA BY ZEROS                 07640000
      *                                                                 07650000
           SET  TI-CF07-88-COD-PROCESO-CON TO TRUE                      07660000
           SET  TI-CF07-88-TIPO-ROL-RECEPT TO TRUE                      07670000
           MOVE TI-CF06-ESTADO             TO TI-CF07-ESTADO            07680000
           MOVE TI-TR02-TRACE-ADQUIRIENTE  TO TI-CF07-TRACE-ADQUIRIENTE 07690000
           MOVE TI-TR02-CANAL              TO TI-CF07-CANAL-CCE         07700000
           MOVE TI-TR02-BIN-ADQUIRIENTE    TO TI-CF07-BIN-ADQUIRIENTE   07710000
           MOVE TI-TR02-TERMINAL-ID        TO TI-CF07-TERMINAL-ID       07720000
           MOVE TI-TR02-DATE-LOCAL         TO TI-CF07-FECHA-TRANS       07730000
           MOVE TI-TR02-TIME-LOCAL         TO TI-CF07-HORA-TRANS        07740000
           MOVE WS-COD-ERROR-07            TO TI-CF07-COD-ERROR         07780000
           MOVE WS-MENSAJE-TXT-EVE         TO TI-CF07-MSG-ERROR         07790000
           MOVE WS-PROGRAM                 TO TI-CF07-PROG              07800000
           MOVE TI-CF06-REG-TRANS          TO TI-CF07-REG-CF06-TRANS    07810000
      *                                                                 07820000
      *    EXEC  CICS  WRITE  FILE (TI-CW03-FILE-EVEN-LOG)              00160022
           EXEC  CICS  WRITE  FILE (WS-FILE-NM-EVEN-LOG)                00160022
                              FROM (TI-CF07-REG-TRANS)                  07840000
                            LENGTH (LENGTH OF TI-CF07-REG-TRANS)        07850000
                            RIDFLD (WS-RBA-ESDS)                        07860000
                               RBA                                      07870000
                              RESP (WS-RESP)                            07880000
           END-EXEC                                                     07890000
      *                                                                 07900000
           EVALUATE WS-RESP                                             07910000
               WHEN DFHRESP(NORMAL)                                     07920000
                    CONTINUE                                            07930000
               WHEN OTHER                                               07940000
                    PERFORM 6000-FINAL                                  08000000
           END-EVALUATE                                                 08010000
           .                                                            08011000
      ************************ FIN DE 1360-GRABAR-LOG-EVENTOS           08011100
      ***************************                                       08025000
       2000-GRABAR-MASTER-TRANSF.                                       08030000
      ***************************                                       08031000
      *-------------------------------------*                           08040000
      * GRABAR EN MAESTRO DE TRANSFERENCIAS *                           08050000
      *-------------------------------------*                           08060000
      *GNS-I                                                            06570000
           MOVE TI-CF06-ID-TRANS-CCE-ONLINE TO TI-CF06-INSTRUCTION-ID   06540000
      *GNS-F                                                            06570000
      *    EXEC CICS WRITE   FILE (TI-CW03-FILE-MAESTRO)                00160022
           EXEC CICS WRITE   FILE (WS-FILE-NM-MAESTRO)                  00160022
                             FROM (TI-CF06-REG-TRANS)                   08080000
                           LENGTH (LENGTH OF TI-CF06-REG-TRANS)         08090000
                           RIDFLD (TI-CF06-REG-KEY-TRANS)               08100000
                        KEYLENGTH (LENGTH OF TI-CF06-REG-KEY-TRANS)     08110000
                             RESP (WS-RESP)                             08120000
           END-EXEC                                                     08130000
                                                                        08140000
           EVALUATE WS-RESP                                             08150000
               WHEN DFHRESP(NORMAL)                                     08160000
                    CONTINUE                                            08170000
               WHEN OTHER                                               08180000
                   MOVE WS-RESP            TO WS-RESP-TXT               08181000
      *            OBTENER MENSAJE PARA CCE                             08190000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08200000
                                                                        08210000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08220000
                   SET  TI-CF06-88-RECH        TO TRUE                  08230000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08240000
                                              WS-TEMP-XX                08250000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08260000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 08270000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08271000
                   MOVE WS-CT-1021N        TO WS-CT-NUMER               08271100
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08271200
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08271300
                                                                        08271400
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08271500
                   PERFORM 1340-ACTUALIZA-COMAREA                       08271600
                                                                        08271700
      *            OBTENER MENSAJE INTERNO                              08271800
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      08271900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  08272000
                   MOVE 'TI0807'           TO TI-CF06-CODMSG-ESTRUCT    08272100
                                              WS-CODMSG-ESTRUCTURA      08272200
                                              WS-COD-ERROR-07           08272300
                   MOVE WS-PROGRAM-ID      TO TI-CF06-PRGNOM            08272400
                                              WS-PROGRAM                08272500
      *            MOVE TI-CW03-FILE-MAESTRO                            00160022
                   MOVE WS-FILE-NM-MAESTRO TO WS-VARMSG-RSO             00160022
                   MOVE WS-RESP-TXT        TO WS-VARMSG-ARG             08272800
                                                                        08272900
                   PERFORM 6100-OBTENER-MENSAJE                         08273000
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        08273100
                                                  WS-MENSAJE-TXT-EVE    08273200
                                                                        08273300
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      08273400
                   PERFORM 6000-FINAL                                   08273500
           END-EVALUATE                                                 08273600
           .                                                            08274000
      *                                                                 08280000
      **************                                                    08281000
       4000-PROCESO.                                                    08290000
      **************                                                    08291000
      ******************************************************************08292000
      * PROCESAMIENTO DEL PROGRAMA                                     *08310000
      ******************************************************************08311000
                                                                        08330000
           EVALUATE TI-TR02-TRANS-EXTENDIDA                             08340000
               WHEN WS-CT-320                                           08350000
                   PERFORM 3000-TRANS-ORDINARIAS                        08360000
                   SET  TI-CF06-88-ACEP    TO TRUE                      08361000
                   MOVE WS-CT-00           TO TI-CF06-RESPONSE-CODE-CCE 08361100
                   MOVE WS-CT-0000         TO TI-CF06-COD-RESP-AMPLIADO 08362000
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08363000
                   MOVE WS-CT-TRANSOK      TO TI-CF06-MENSAJE-RESPUESTA 08364000
                                                                        08365000
               WHEN WS-CT-325                                           08370000
                   PERFORM 3400-PAGO-A-CUENTA-TCRE                      08380000
                   SET  TI-CF06-88-ACEP    TO TRUE                      08381000
                   MOVE WS-CT-0000         TO TI-CF06-COD-RESP-AMPLIADO 08382000
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08383000
                   MOVE WS-CT-TRANSOK      TO TI-CF06-MENSAJE-RESPUESTA 08384000
                                                                        08385000
               WHEN OTHER                                               08390000
      *            OBTENER MENSAJE PARA CCE                             08471000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08472000
                                                                        08473000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08474000
                   SET  TI-CF06-88-RECH        TO TRUE                  08475000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08476000
                                              WS-TEMP-XX                08477000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08478000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 08479000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08479100
                   MOVE WS-CT-1006N        TO WS-CT-NUMER               08479200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08479300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08479400
                                                                        08479500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08479600
                                                                        08479700
      *            OBTENER MENSAJE INTERNO                              08479800
                   MOVE WS-CODMSG-ESTRUCTURA                            08479900
                                           TO WS-COD-ERROR-07           08480000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                08480100
                                                                        08480200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        08480300
                                                                        08480400
                                                                        08480500
                   PERFORM 1340-ACTUALIZA-COMAREA                       08480600
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      08480700
                   PERFORM 6000-FINAL                                   08480800
           END-EVALUATE                                                 08481000
           .                                                            08482000
      ************************ FIN DE 4000-PROCESO                      08490000
      ***********************                                           08491000
       3000-TRANS-ORDINARIAS.                                           08500000
      ***********************                                           08501000
      *                                                                 08520000
           EVALUATE TI-TR02-CCI-CLI-BENEFICIA(16:1)                     08530000
              WHEN WS-CT-0                                              08540000
                 IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-604           08550000
      *            OBTENER MENSAJE PARA CCE                             08641000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08642000
                                                                        08643000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08644000
                   SET  TI-CF06-88-RECH        TO TRUE                  08645000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08646000
                                              WS-TEMP-XX                08647000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08648000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1009         TO TI-CF06-COD-RESP-AMPLIADO 08649000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08649100
                   MOVE WS-CT-1009N        TO WS-CT-NUMER               08649200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08649300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08649400
                                                                        08649500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08649600
                                                                        08649700
      *            OBTENER MENSAJE INTERNO                              08649800
                   MOVE WS-CODMSG-ESTRUCTURA                            08649900
                                           TO WS-COD-ERROR-07           08650000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                08650100
                                                                        08650200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        08650300
                                                                        08650400
                                                                        08650500
                   PERFORM 1340-ACTUALIZA-COMAREA                       08650600
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      08650700
                   PERFORM 6000-FINAL                                   08650800
                 END-IF                                                 08651000
      *                                                                 08660000
              WHEN WS-CT-1                                              08670000
                 IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-840           08680000
      *            OBTENER MENSAJE PARA CCE                             08771000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08772000
                                                                        08773000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08774000
                   SET  TI-CF06-88-RECH        TO TRUE                  08775000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08776000
                                              WS-TEMP-XX                08777000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08778000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1009         TO TI-CF06-COD-RESP-AMPLIADO 08779000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08779100
                   MOVE WS-CT-1009N        TO WS-CT-NUMER               08779200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08779300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08779400
                                                                        08779500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08779600
                                                                        08779700
      *            OBTENER MENSAJE INTERNO                              08779800
                   MOVE WS-CODMSG-ESTRUCTURA                            08779900
                                           TO WS-COD-ERROR-07           08780000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                08780100
                                                                        08780200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        08780300
                                                                        08780400
                                                                        08780500
                   PERFORM 1340-ACTUALIZA-COMAREA                       08780600
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      08780700
                   PERFORM 6000-FINAL                                   08780800
                 END-IF                                                 08781000
      *                                                                 08790000
              WHEN OTHER                                                08800000
      *            OBTENER MENSAJE PARA CCE                             08881000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  08882000
                                                                        08883000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  08884000
                   SET  TI-CF06-88-RECH        TO TRUE                  08885000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 08886000
                                              WS-TEMP-XX                08887000
                                              WS-CODMSG-ESTRUCTURA(1: 2)08888000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1009         TO TI-CF06-COD-RESP-AMPLIADO 08889000
                                              WS-CODMSG-ESTRUCTURA(3: 4)08889100
                   MOVE WS-CT-1009N        TO WS-CT-NUMER               08889200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  08889300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         08889400
                                                                        08889500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 08889600
                                                                        08889700
      *            OBTENER MENSAJE INTERNO                              08889800
                   MOVE WS-CODMSG-ESTRUCTURA                            08889900
                                           TO WS-COD-ERROR-07           08890000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                08890100
                                                                        08890200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        08890300
                                                                        08890400
                                                                        08890500
                   PERFORM 1340-ACTUALIZA-COMAREA                       08890600
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      08890700
                   PERFORM 6000-FINAL                                   08890800
                                                                        08890900
           END-EVALUATE                                                 08891000
      *                                                                 08900000
           EVALUATE TI-TR02-CCI-CLI-BENEFICIA(7:1)                      08910000
               WHEN WS-CT-0                                             08920000
                   PERFORM 3100-CUENTA-IMPACS                           08930000
      *                                                                 08940000
               WHEN WS-CT-1                                             08950000
                   PERFORM 3200-CUENTA-SAVING                           08960000
      *                                                                 08970000
               WHEN OTHER                                               08980000
      *            OBTENER MENSAJE PARA CCE                             09061000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  09062000
                                                                        09063000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  09064000
                   SET  TI-CF06-88-RECH        TO TRUE                  09065000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 09066000
                                              WS-TEMP-XX                09067000
                                              WS-CODMSG-ESTRUCTURA(1: 2)09068000
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1016         TO TI-CF06-COD-RESP-AMPLIADO 09069000
                                              WS-CODMSG-ESTRUCTURA(3: 4)09069100
                   MOVE WS-CT-1016N        TO WS-CT-NUMER               09069200
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  09069300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         09069400
                                                                        09069500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 09069600
                                                                        09069700
      *            OBTENER MENSAJE INTERNO                              09069800
                   MOVE WS-CODMSG-ESTRUCTURA                            09069900
                                           TO WS-COD-ERROR-07           09070000
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                09070100
                                                                        09070200
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        09070300
                                                                        09070400
                                                                        09070500
                   PERFORM 1340-ACTUALIZA-COMAREA                       09070600
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      09070700
                   PERFORM 6000-FINAL                                   09070800
           END-EVALUATE.                                                09071000
      *                                                                 09080000
      *PROCEDIMIENTO PARA VALIDAR QUE LA CUENTA BENEFICIARIA LE PERTENE 09090000
      *AL ORDENANTE.                                                    09100000
                                                                        09110000
           MOVE WS-CT-4                           TO DGC-IND-CLAVE      09120000
           IF TI-TR02-CCI-CLI-BENEFICIA(7:1) = ZEROS                    09130000
              MOVE 'CTE'    TO DGC-GLS-SERVICIO                         09140000
              MOVE TI-TR02-CCI-CLI-BENEFICIA(4:3) TO DGC-GLS-CLAVE(1:3) 09150000
              MOVE '0'                            TO DGC-GLS-CLAVE(4:1) 09160000
              MOVE TI-TR02-CCI-CLI-BENEFICIA(9:10)                      09170000
                                                  TO DGC-GLS-CLAVE(5:10)09180000
           ELSE                                                         09190000
              MOVE TI-TR02-CCI-CLI-BENEFICIA(4:3) TO DGC-GLS-CLAVE(1:3) 09200000
              MOVE TI-TR02-CCI-CLI-BENEFICIA(8:11)                      09210000
                                                  TO DGC-GLS-CLAVE(4:11)09220000
              MOVE 'AHO'       TO DGC-GLS-SERVICIO                      09230000
              STRING TI-TR02-CCI-CLI-BENEFICIA(4:3)                     09240000
                     TI-TR02-CCI-CLI-BENEFICIA(8:11)                    09250000
                     DELIMITED BY SIZE INTO DGC-GLS-CLAVE               09260000
              END-STRING                                                09270000
           END-IF                                                       09280000
           MOVE TI-TR02-TIP-DOC-CLI-ORIG   TO WS-TIPO-DOC-ORD-HOMOL     09281000
           PERFORM 4155-HOMOLOGA-DOC                                    09290000
           MOVE WS-TIPO-DOC-ORD-HOMOL      TO TI-CF06-TIP-DOC-CLI-ORIG  09291000
      *                                                                 09300000
           EXEC CICS LINK                                               09310000
                     PROGRAM (WS-RTN-SGCPPDGC)                          09320000
                     COMMAREA(SGCWGDGC)                                 09330000
                     LENGTH  (LENGTH OF SGCWGDGC)                       09340000
                     RESP    (WS-RESP)                                  09360000
           END-EXEC                                                     09370000
      *                                                                 09380000
           IF DGC-CRETORNO(1) = WS-CT-0000                              09390000
              MOVE WS-CT-1N  TO IND                                     09400000
      *                                                                 09410000
              PERFORM UNTIL IND > WS-CT-5N OR                           09420000
                      DGC-NUM-ICLI(IND) = SPACES                        09430000
                PERFORM 3700-FORMATEAR-DOCUMENTO                        09440000
                                                                        09450000
      *                                                                 09610000
                EVALUATE WS-TIPO-DOC-ORD-HOMOL                          09611000
                  WHEN "6"                                              09611100
                      IF DGC-COD-IRUC(IND)  =                           09611200
                                          TI-TR02-NRO-DOC-CLI-ORIG(1:11)09611300
                         MOVE IND          TO INDOK                     09611400
                         MOVE WS-CT-6N     TO IND                       09611500
                         MOVE 1            TO WS-CUENTA-PROPIA-SI       09611600
                      END-IF                                            09611700
                                                                        09611800
                  WHEN "3"                                              09611900
                  WHEN "4"                                              09612000
                      MOVE SPACES              TO WS-DOC-ORD-TMP        09612100
                      MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        09612200
                      PERFORM 5000-REORDENAR-DOCUMENTO                  09612300
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    09612400
                                                                        09612500
                      MOVE SPACES              TO WS-DOC-ORD-TMP        09612600
                      MOVE TI-TR02-NRO-DOC-CLI-ORIG                     09612700
                                               TO WS-DOC-ORD-TMP        09612800
                      PERFORM 5000-REORDENAR-DOCUMENTO                  09612900
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        09613000
                                                                        09613100
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 09613200
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  09613300
                         MOVE IND                TO INDOK               09613400
                         MOVE WS-CT-6N           TO IND                 09613500
                         MOVE 1                  TO WS-CUENTA-PROPIA-SI 09613600
                                                                        09613800
                      END-IF                                            09613900
                                                                        09614000
                  WHEN OTHER                                            09614100
                      IF DGC-NUM-ICLI(IND) =                            09614200
                                           TI-TR02-NRO-DOC-CLI-ORIG(1:8)09614300
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  09614400
                         MOVE IND                TO INDOK               09614500
                         MOVE WS-CT-6N           TO IND                 09614600
                         MOVE 1                  TO WS-CUENTA-PROPIA-SI 09614700
                      END-IF                                            09614800
                                                                        09614900
                END-EVALUATE                                            09615000
                                                                        09616000
                COMPUTE IND = IND + 1                                   09620000
                END-COMPUTE                                             09630000
              END-PERFORM                                               09640000
      *                                                                 09650000
              IF WS-TIPO-DOC-ORD-HOMOL = WS-CT-6                        09660000
                 IF WS-CUENTA-PROPIA-SI = 1                             09670000
                    INSPECT DGC-GLS-NOMC(INDOK) CONVERTING              09671000
                                 WS-FINDREPLACE TO WS-REPLACE           09672000
                    MOVE DGC-GLS-NOMC(INDOK) TO TI-TR02-APE-PAT-CLI-BENE09680000
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           09690000
                    STRING WS-CT-SPACE4                                 09700000
                      DGC-NUM-ICLI(INDOK)                               09710000
                      DGC-IND-ICLI(INDOK)                               09720000
                      DGC-GLS-ICLI(INDOK)                               09730000
                      DELIMITED BY SIZE INTO WS-IDC                     09740000
                    END-STRING                                          09750000
                    MOVE WS-CT-M TO TI-TR02-INDI-MISMO-CLIENTE          09760000
                 ELSE                                                   09770000
                    INSPECT DGC-GLS-NOMC(1) CONVERTING                  09771000
                                 WS-FINDREPLACE TO WS-REPLACE           09772000
                    MOVE DGC-GLS-NOMC(1) TO TI-TR02-APE-PAT-CLI-BENE    09780000
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           09790000
                    STRING WS-CT-SPACE4                                 09800000
                       DGC-NUM-ICLI(1)                                  09810000
                       DGC-IND-ICLI(1)                                  09820000
                       DGC-GLS-ICLI(1)                                  09830000
                       DELIMITED BY SIZE INTO WS-IDC                    09840000
                    END-STRING                                          09850000
                    MOVE WS-CT-O   TO TI-TR02-INDI-MISMO-CLIENTE        09860000
                 END-IF                                                 09870000
              ELSE                                                      09880000
                 IF WS-CUENTA-PROPIA-SI = 1                             09890000
                    INSPECT DGC-GLS-APAT(INDOK) CONVERTING              09891000
                                 WS-FINDREPLACE TO WS-REPLACE           09892000
                    MOVE DGC-GLS-APAT(INDOK) TO TI-TR02-APE-PAT-CLI-BENE09900000
                    INSPECT DGC-GLS-AMAT(INDOK) CONVERTING              09901000
                                 WS-FINDREPLACE TO WS-REPLACE           09902000
                    MOVE DGC-GLS-AMAT(INDOK) TO TI-TR02-APE-MAT-CLI-BENE09910000
                    INSPECT DGC-GLS-NOMB(INDOK) CONVERTING              09911000
                                 WS-FINDREPLACE TO WS-REPLACE           09912000
                    MOVE DGC-GLS-NOMB(INDOK) TO TI-TR02-NOMBRE-CLI-BENE 09920000
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           09930000
                    STRING WS-CT-SPACE4                                 09940000
                         DGC-NUM-ICLI(INDOK)                            09950000
                         DGC-IND-ICLI(INDOK)                            09960000
                         DGC-GLS-ICLI(INDOK)                            09970000
                         DELIMITED BY SIZE INTO WS-IDC                  09980000
                    END-STRING                                          09990000
                    MOVE WS-CT-M           TO TI-TR02-INDI-MISMO-CLIENTE10000000
                 ELSE                                                   10010000
                    INSPECT DGC-GLS-APAT(1) CONVERTING                  10011000
                                 WS-FINDREPLACE TO WS-REPLACE           10012000
                    MOVE DGC-GLS-APAT(1)   TO TI-TR02-APE-PAT-CLI-BENE  10020000
                    INSPECT DGC-GLS-AMAT(1) CONVERTING                  10021000
                                 WS-FINDREPLACE TO WS-REPLACE           10022000
                    MOVE DGC-GLS-AMAT(1)   TO TI-TR02-APE-MAT-CLI-BENE  10030000
                    INSPECT DGC-GLS-NOMB(1) CONVERTING                  10031000
                                 WS-FINDREPLACE TO WS-REPLACE           10032000
                    MOVE DGC-GLS-NOMB(1)   TO TI-TR02-NOMBRE-CLI-BENE   10040000
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           10050000
                    STRING WS-CT-SPACE4                                 10060000
                         DGC-NUM-ICLI(1)                                10070000
                         DGC-IND-ICLI(1)                                10080000
                         DGC-GLS-ICLI(1)                                10090000
                         DELIMITED BY SIZE INTO WS-IDC                  10100000
                     END-STRING                                         10110000
                     MOVE WS-CT-O          TO TI-TR02-INDI-MISMO-CLIENTE10120000
                  END-IF                                                10130000
              END-IF                                                    10140000
                                                                        10141000
              IF  DGC-NUM-ICLI(WS-CT-2N) NOT EQUAL (SPACES              10142000
                                                    AND LOW-VALUES      10142100
                                                    AND HIGH-VALUES)    10142200
                  OR INDOK > WS-CT-1N                                   10142300
                  MOVE WS-CT-O          TO TI-TR02-INDI-MISMO-CLIENTE   10142400
                                                                        10143000
              END-IF                                                    10144000
      *                                                                 10150000
           ELSE                                                         10200000
              IF  (WS-CT-0001 = DGC-CRETORNO(1) OR                      10220000
                   WS-CT-0002 = DGC-CRETORNO(1) OR                      10230000
                   WS-CT-0003 = DGC-CRETORNO(1) OR                      10240000
                   WS-CT-0009 = DGC-CRETORNO(1) )                       10250000
      *            OBTENER MENSAJE PARA CCE                             10260000
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  10270000
                                                                        10280000
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  10290000
                   SET  TI-CF06-88-RECH        TO TRUE                  10300000
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 10310000
                                              WS-TEMP-XX                10320000
                                              WS-CODMSG-ESTRUCTURA(1: 2)10330000
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)10340100
      *            MOVE WS-CT-1007N        TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006N        TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  10340300
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         10340400
                                                                        10340500
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 10340600
                                                                        10340700
      *            OBTENER MENSAJE INTERNO                              10340800
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    10341500
                                              WS-COD-ERROR-07           10341600
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            10341700
                                              WS-PROGRAM                10341800
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            10341900
                                              WS-MENSAJE-TXT-EVE        10342000
                                                                        10342100
                   PERFORM 1340-ACTUALIZA-COMAREA                       10342200
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      10342300
                   PERFORM 6000-FINAL                                   10342400
              ELSE                                                      10343000
                IF (WS-CT-2002 = DGC-CRETORNO(1) OR                     10360000
                    WS-CT-2008 = DGC-CRETORNO(1) )                      10370000
      *             OBTENER MENSAJE PARA CCE                            10451000
                    MOVE SPACES                 TO TI-CA15-I-O-MENSAJES 10452000
                                                                        10453000
                    SET  TI-CA15-I-RC-APP-CCE   TO TRUE                 10454000
                    SET  TI-CF06-88-RECH        TO TRUE                 10455000
                    MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE10456000
                                              WS-TEMP-XX                10457000
                                              WS-CODMSG-ESTRUCTURA(1: 2)10458000
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO10459000
                                              WS-CODMSG-ESTRUCTURA(3: 4)10459100
                    MOVE WS-CT-1002N        TO WS-CT-NUMER              10459200
                                               TI-TR02-COD-RESP-AMPLIADO        
                    MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA 10459300
                                               TI-TR02-ORIGEN-RESPUESTA         
                    PERFORM 6100-OBTENER-MENSAJE                        10459400
                                                                        10459500
                    MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA10459600
                                                                        10459700
      *             OBTENER MENSAJE INTERNO                             10459800
                    MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT   10459900
                                               WS-COD-ERROR-07          10460000
                    MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM           10460100
                                               WS-PROGRAM               10460200
                    MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG           10460300
                                               WS-MENSAJE-TXT-EVE       10460400
                                                                        10461200
                    PERFORM 1340-ACTUALIZA-COMAREA                      10461300
                    PERFORM 1360-GRABAR-LOG-EVENTOS                     10461400
                    PERFORM 6000-FINAL                                  10461500
                ELSE                                                    10462000
      *             OBTENER MENSAJE PARA CCE                            10581000
                    MOVE SPACES                 TO TI-CA15-I-O-MENSAJES 10582000
                                                                        10583000
                    SET  TI-CA15-I-RC-APP-CCE   TO TRUE                 10584000
                    SET  TI-CF06-88-RECH        TO TRUE                 10585000
                    MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE10586000
                                              WS-TEMP-XX                10587000
                                              WS-CODMSG-ESTRUCTURA(1: 2)10588000
                                              TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO00160022
                    MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)10589100
      *             MOVE WS-CT-1008N        TO WS-CT-NUMER              00160022
                    MOVE WS-CT-1006N        TO WS-CT-NUMER              00160022
                                               TI-TR02-COD-RESP-AMPLIADO        
                    MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA 10589300
                                               TI-TR02-ORIGEN-RESPUESTA         
                    PERFORM 6100-OBTENER-MENSAJE                        10589400
                                                                        10589500
                    MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA10589600
                                                                        10589700
      *             OBTENER MENSAJE INTERNO                             10589800
                    MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT   10589900
                                               WS-COD-ERROR-07          10590000
                    MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM           10590100
                                               WS-PROGRAM               10590200
                    MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG           10590300
                                               WS-MENSAJE-TXT-EVE       10590400
                                                                        10591100
                    PERFORM 1340-ACTUALIZA-COMAREA                      10591200
                    PERFORM 1360-GRABAR-LOG-EVENTOS                     10591300
                    PERFORM 6000-FINAL                                  10591400
               END-IF                                                   10592000
           END-IF                                                       10600000
           .                                                            10601000
      ************************ FIN DE 3000-TRANS-ORDINARIAS             10602000
      ********************                                              10610000
       3100-CUENTA-IMPACS.                                              10620000
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
           MOVE TI-TR02-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     10760000
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
           PERFORM 4180-ASIGNAR-TERM-USER                               10951000
           MOVE RG-CA04-I-HDR-STD-IN   TO CA-IM-HEADER-ESTANDAR-I       10951100
                                                                        10952000
           MOVE SPACES           TO CA-IM-COD-CTA-COM-I                 10960000
           MOVE TI-TR02-CCI-CLI-BENEFICIA(4:3)                          10970000
                                 TO CA-IM-COD-CTA-COM-I(8:3)            10980000
           MOVE TI-TR02-CCI-CLI-BENEFICIA(9:10)                         10990000
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
           EXEC CICS LINK PROGRAM (TI-CW03-SRV-IMDS)                    11150000
                          COMMAREA(CA-IM-REG-INQ)                       11160000
                          LENGTH  (LENGTH OF CA-IM-REG-INQ)             11170000
                          RESP    (WS-RESP)                             11190000
                          RESP2   (WS-RESP2)                            11200000
           END-EXEC                                                     11210000
      *                                                                 11220000
           EVALUATE WS-RESP                                             11230000
             WHEN NOT DFHRESP(NORMAL)                                   11240000
      *        OBTENER MENSAJE PARA CCE                                 11351000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      11352000
                                                                        11353000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      11354000
               SET  TI-CF06-88-RECH        TO TRUE                      11355000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 11356000
                                              WS-TEMP-XX                11357000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11358000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 11359000
                                              WS-CODMSG-ESTRUCTURA(3: 4)11359100
               MOVE WS-CT-1021N            TO WS-CT-NUMER               11359200
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  11359300
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             11359400
                                                                        11359500
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 11359600
               PERFORM 1340-ACTUALIZA-COMAREA                           11359700
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
               MOVE TI-CW03-SRV-IMDS       TO WS-VARMSG-RSO             11360800
                                                                        11360900
               PERFORM 6100-OBTENER-MENSAJE                             11361000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            11361100
                                              WS-MENSAJE-TXT-EVE        11361200
                                                                        11361300
               PERFORM 1360-GRABAR-LOG-EVENTOS                          11361400
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
                       MOVE SPACES         TO TI-CA15-I-O-MENSAJES      11562000
                                                                        11563000
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              11564000
                       SET  TI-CF06-88-RECH        TO TRUE              11565000
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 11566000
                                              WS-TEMP-XX                11567000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11568000
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1001     TO TI-CF06-COD-RESP-AMPLIADO 11569000
                                              WS-CODMSG-ESTRUCTURA(3: 4)11569100
                       MOVE WS-CT-1001N    TO WS-CT-NUMER               11569200
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  11569300
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     11569400
                                                                        11569500
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 11569600
                                                                        11569700
      *                OBTENER MENSAJE INTERNO                          11569800
                       MOVE WS-CODMSG-ESTRUCTURA                        11569900
                                           TO WS-COD-ERROR-07           11570000
                       MOVE WS-PROGRAM-ID  TO WS-PROGRAM                11570100
                                                                        11570200
                       MOVE WS-MENSAJE-TXT TO WS-MENSAJE-TXT-EVE        11570300
                                                                        11570400
                                                                        11570500
                       PERFORM 1340-ACTUALIZA-COMAREA                   11570600
                       PERFORM 1360-GRABAR-LOG-EVENTOS                  11570700
                       PERFORM 6000-FINAL                               11570800
                   END-IF                                               11571000
      *                                                                 11580000
                   IF (WS-CT-01 = CA-IM-STAT-CTA-COD(3:2) OR            11590000
                       WS-CT-03 = CA-IM-STAT-CTA-COD(3:2))              11600000
      *                OBTENER MENSAJE PARA CCE                         11681000
                       MOVE SPACES         TO TI-CA15-I-O-MENSAJES      11682000
                                                                        11683000
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              11684000
                       SET  TI-CF06-88-RECH        TO TRUE              11685000
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 11686000
                                              WS-TEMP-XX                11687000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11688000
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1001     TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)11689100
                       MOVE WS-CT-1001N    TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  11689300
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     11689400
                                                                        11689500
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 11689600
                                                                        11689700
      *                OBTENER MENSAJE INTERNO                          11689800
                       MOVE WS-CODMSG-ESTRUCTURA                        11689900
                                           TO WS-COD-ERROR-07           11690000
                       MOVE WS-PROGRAM-ID  TO WS-PROGRAM                11690100
                                                                        11690200
                       MOVE WS-MENSAJE-TXT TO WS-MENSAJE-TXT-EVE        11690300
                                                                        11690400
                                                                        11690500
                       PERFORM 1340-ACTUALIZA-COMAREA                   11690600
                       PERFORM 1360-GRABAR-LOG-EVENTOS                  11690700
                       PERFORM 6000-FINAL                               11690800
                   END-IF                                               11691000
                ELSE                                                    11700000
                   EVALUATE TRUE                                        11710000
                   WHEN WS-CT-IM0316 = CA-IM-COD-RET                    11720000
      *               OBTENER MENSAJE PARA CCE                          11801000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  11802000
                                                                        11803000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              11804000
                      SET  TI-CF06-88-RECH         TO TRUE              11805000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 11806000
                                              WS-TEMP-XX                11807000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11808000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1002      TO TI-CF06-COD-RESP-AMPLIADO 11809000
                                              WS-CODMSG-ESTRUCTURA(3: 4)11809100
                      MOVE WS-CT-1002N     TO WS-CT-NUMER               11809200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  11809300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      11809400
                                                                        11809500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 11809600
                                                                        11809700
      *               OBTENER MENSAJE INTERNO                           11809800
                      MOVE CA-IM-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    11809900
                                              WS-COD-ERROR-07           11810000
                      MOVE TI-CW03-SRV-IMDS    TO TI-CF06-PRGNOM        11810100
                                                  WS-PROGRAM            11810200
                      MOVE CA-IM-TXT-RET   TO TI-CF06-TXTMSG            11810300
                                              WS-MENSAJE-TXT-EVE        11810400
                                                                        11810500
                      PERFORM 1340-ACTUALIZA-COMAREA                    11810600
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   11810700
                      PERFORM 6000-FINAL                                11810800
      *                                                                 11820000
                   WHEN WS-CT-IM0304 = CA-IM-COD-RET                    11830000
                   WHEN WS-CT-IM0504 = CA-IM-COD-RET                    11840000
      *               OBTENER MENSAJE PARA CCE                          11841000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  11842000
                                                                        11843000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              11844000
                      SET  TI-CF06-88-RECH         TO TRUE              11845000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 11846000
                                              WS-TEMP-XX                11847000
                                              WS-CODMSG-ESTRUCTURA(1: 2)11848000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1006      TO TI-CF06-COD-RESP-AMPLIADO 11849000
                                              WS-CODMSG-ESTRUCTURA(3: 4)11849100
                      MOVE WS-CT-1006N     TO WS-CT-NUMER               11849200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  11849300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      11849400
                                                                        11849500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 11849600
                                                                        11849700
      *               OBTENER MENSAJE INTERNO                           11849800
                      MOVE CA-IM-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    11849900
                                              WS-COD-ERROR-07           11850000
                      MOVE TI-CW03-SRV-IMDS    TO TI-CF06-PRGNOM        11850100
                                                  WS-PROGRAM            11850200
                      MOVE CA-IM-TXT-RET   TO TI-CF06-TXTMSG            11850300
                                              WS-MENSAJE-TXT-EVE        11850400
                      PERFORM 1340-ACTUALIZA-COMAREA                    11850500
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   11850600
                      PERFORM 6000-FINAL                                11850700
      *                                                                 11940000
                   WHEN WS-CT-IM0604 = CA-IM-COD-RET                    11950000
      *               OBTENER MENSAJE PARA CCE                          12031000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  12032000
                                                                        12033000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              12034000
                      SET  TI-CF06-88-RECH         TO TRUE              12035000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 12036000
                                              WS-TEMP-XX                12037000
                                              WS-CODMSG-ESTRUCTURA(1: 2)12038000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1002      TO TI-CF06-COD-RESP-AMPLIADO 12039000
                                              WS-CODMSG-ESTRUCTURA(3: 4)12039100
                      MOVE WS-CT-1002N     TO WS-CT-NUMER               12039200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  12039300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      12039400
                                                                        12039500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 12039600
                                                                        12039700
      *               OBTENER MENSAJE INTERNO                           12039800
                      MOVE CA-IM-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    12039900
                                              WS-COD-ERROR-07           12040000
                      MOVE TI-CW03-SRV-IMDS    TO TI-CF06-PRGNOM        12040100
                                                  WS-PROGRAM            12040200
                      MOVE CA-IM-TXT-RET   TO TI-CF06-TXTMSG            12040300
                                              WS-MENSAJE-TXT-EVE        12040400
                      PERFORM 1340-ACTUALIZA-COMAREA                    12040500
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   12040600
                      PERFORM 6000-FINAL                                12040700
      *                                                                 12050000
                   WHEN OTHER                                           12050100
      *               OBTENER MENSAJE PARA CCE                          12051000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  12052000
                                                                        12053000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              12054000
                      SET  TI-CF06-88-RECH         TO TRUE              12055000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 12056000
                                              WS-TEMP-XX                12057000
                                              WS-CODMSG-ESTRUCTURA(1: 2)12058000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO 12059000
                                              WS-CODMSG-ESTRUCTURA(3: 4)12059100
                      MOVE WS-CT-1021N     TO WS-CT-NUMER               12059200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  12059300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      12059400
                                                                        12059500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 12059600
                                                                        12059700
      *               OBTENER MENSAJE INTERNO                           12059800
                      MOVE CA-IM-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    12059900
                                              WS-COD-ERROR-07           12060000
                      MOVE TI-CW03-SRV-IMDS    TO TI-CF06-PRGNOM        12060100
                                                  WS-PROGRAM            12060200
                      MOVE CA-IM-TXT-RET   TO TI-CF06-TXTMSG            12060300
                                              WS-MENSAJE-TXT-EVE        12060400
                      PERFORM 1340-ACTUALIZA-COMAREA                    12060500
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   12060600
                      PERFORM 6000-FINAL                                12060700
                   END-EVALUATE                                         12200000
                END-IF                                                  12201000
           END-EVALUATE                                                 12210000
           .                                                            12211000
      ************************ FIN DE 3100-CUENTA-IMPACS                12220000
      ********************                                              12221000
       3200-CUENTA-SAVING.                                              12230000
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
           MOVE TI-TR02-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     12400000
           MOVE WS-NRO-OPERACION           TO CA-ST-NRO-OPERACION-I     12410000
           MOVE WS-CT-01           TO CA-ST-NRO-VERSION-I               12420000
           MOVE WS-CT-0            TO CA-ST-FLAG-EXTORNO-I              12430000
           MOVE SPACES             TO CA-ST-HEADER-DISPONIBLE-I         12440000
      *                                                                 12450000
           MOVE SPACES             TO CA-ST-COD-CTA-COM-I               12460000
           MOVE TI-TR02-CCI-CLI-BENEFICIA(4:3)                          12470000
                                   TO CA-ST-COD-CTA-COM-I(1:3)          12480000
           MOVE TI-TR02-CCI-CLI-BENEFICIA(8:11)                         12490000
                                   TO CA-ST-COD-CTA-COM-I(4:11)         12500000
           MOVE WS-CT-001          TO CA-ST-COD-PRD-ST-I                12510000
           MOVE SPACES             TO CA-ST-FLAG-COBCOM-I               12520000
           MOVE CA-ST-HEADER-ESTANDAR-I                                 12530000
                                       TO RG-CA04-I-HDR-STD-IN          12530100
                                          RG-CA10-I-INPUT-CANAL-HEADER  12530200
           PERFORM 4180-ASIGNAR-TERM-USER                               12531000
           MOVE RG-CA04-I-HDR-STD-IN       TO CA-ST-HEADER-ESTANDAR-I   12540000
      *                                                                 12550000
           EXEC CICS LINK PROGRAM (TI-CW03-SRV-STDA)                    12560000
                          COMMAREA(CA-ST-REG-INQ)                       12570000
                          LENGTH  (LENGTH OF CA-ST-REG-INQ)             12580000
                          RESP    (WS-RESP)                             12600000
                          RESP2   (WS-RESP2)                            12610000
           END-EXEC                                                     12620000
                                                                        12630000
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         12640000
      *       OBTENER MENSAJE PARA CCE                                  12771000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       12772000
                                                                        12773000
              SET  TI-CA15-I-RC-APP-CCE   TO TRUE                       12774000
              SET  TI-CF06-88-RECH        TO TRUE                       12775000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  12776000
                                             WS-TEMP-XX                 12777000
                                             WS-CODMSG-ESTRUCTURA(1: 2) 12778000
                                             TI-TR02-RESPONSE-CODE-CCE          
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  12779000
                                             WS-CODMSG-ESTRUCTURA(3: 4) 12779100
              MOVE WS-CT-1021N            TO WS-CT-NUMER                12779200
                                             TI-TR02-COD-RESP-AMPLIADO          
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   12779300
                                             TI-TR02-ORIGEN-RESPUESTA           
              PERFORM 6100-OBTENER-MENSAJE                              12779400
                                                                        12779500
              MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA  12779600
              PERFORM 1340-ACTUALIZA-COMAREA                            12779700
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
              MOVE TI-CW03-SRV-STDA       TO WS-VARMSG-RSO              12780800
                                                                        12780900
              PERFORM 6100-OBTENER-MENSAJE                              12781000
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             12781100
                                             WS-MENSAJE-TXT-EVE         12781200
                                                                        12781300
              PERFORM 1360-GRABAR-LOG-EVENTOS                           12781400
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
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES      13022000
                                                                        13023000
                     SET  TI-CA15-I-RC-APP-CCE TO TRUE                  13024000
                     SET  TI-CF06-88-RECH      TO TRUE                  13025000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 13026000
                                              WS-TEMP-XX                13027000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13028000
                                              TI-TR02-RESPONSE-CODE-CCE         
                     MOVE WS-CT-1001       TO TI-CF06-COD-RESP-AMPLIADO 13029000
                                              WS-CODMSG-ESTRUCTURA(3: 4)13029100
                     MOVE WS-CT-1001N      TO WS-CT-NUMER               13029200
                                              TI-TR02-COD-RESP-AMPLIADO         
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  13029300
                                              TI-TR02-ORIGEN-RESPUESTA          
                     PERFORM 6100-OBTENER-MENSAJE                       13029400
                                                                        13029500
                     MOVE WS-MENSAJE-TXT   TO TI-CF06-MENSAJE-RESPUESTA 13029600
                                                                        13029700
      *                OBTENER MENSAJE INTERNO                          13029800
                     MOVE WS-CODMSG-ESTRUCTURA                          13029900
                                           TO WS-COD-ERROR-07           13030000
                     MOVE WS-PROGRAM-ID    TO WS-PROGRAM                13030100
                                                                        13030200
                     MOVE WS-MENSAJE-TXT   TO WS-MENSAJE-TXT-EVE        13030300
                                                                        13030400
                                                                        13030500
                     PERFORM 1340-ACTUALIZA-COMAREA                     13030600
                     PERFORM 1360-GRABAR-LOG-EVENTOS                    13030700
                     PERFORM 6000-FINAL                                 13030800
                 END-IF                                                 13031000
      *                                                                 13040000
                 IF (WS-CT-06 = CA-ST-STA-CTA-COD(3:2) OR               13050000
                     WS-CT-08 = CA-ST-STA-CTA-COD(3:2))                 13060000
      *              OBTENER MENSAJE PARA CCE                           13141000
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES      13142000
                                                                        13143000
                     SET  TI-CA15-I-RC-APP-CCE TO TRUE                  13144000
                     SET  TI-CF06-88-RECH      TO TRUE                  13145000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 13146000
                                              WS-TEMP-XX                13147000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13148000
                                              TI-TR02-RESPONSE-CODE-CCE         
                     MOVE WS-CT-1001       TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)13149100
                     MOVE WS-CT-1001N      TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  13149300
                                              TI-TR02-ORIGEN-RESPUESTA          
                     PERFORM 6100-OBTENER-MENSAJE                       13149400
                                                                        13149500
                     MOVE WS-MENSAJE-TXT   TO TI-CF06-MENSAJE-RESPUESTA 13149600
                                                                        13149700
      *                OBTENER MENSAJE INTERNO                          13149800
                     MOVE WS-CODMSG-ESTRUCTURA                          13149900
                                           TO WS-COD-ERROR-07           13150000
                     MOVE WS-PROGRAM-ID    TO WS-PROGRAM                13150100
                                                                        13150200
                     MOVE WS-MENSAJE-TXT   TO WS-MENSAJE-TXT-EVE        13150300
                                                                        13150400
                                                                        13150500
                     PERFORM 1340-ACTUALIZA-COMAREA                     13150600
                     PERFORM 1360-GRABAR-LOG-EVENTOS                    13150700
                     PERFORM 6000-FINAL                                 13150800
                 END-IF                                                 13151000
              ELSE                                                      13160000
                 EVALUATE CA-ST-COD-RET                                 13170000
                   WHEN WS-CT-ST0316                                    13180000
      *               OBTENER MENSAJE PARA CCE                          13261000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  13262000
                                                                        13263000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              13264000
                      SET  TI-CF06-88-RECH         TO TRUE              13265000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13266000
                                              WS-TEMP-XX                13267000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13268000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1002      TO TI-CF06-COD-RESP-AMPLIADO 13269000
                                              WS-CODMSG-ESTRUCTURA(3: 4)13269100
                      MOVE WS-CT-1002N     TO WS-CT-NUMER               13269200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13269300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      13269400
                                                                        13269500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 13269600
                                                                        13269700
      *               OBTENER MENSAJE INTERNO                           13269800
                      MOVE CA-ST-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    13269900
                                              WS-COD-ERROR-07           13270000
                      MOVE TI-CW03-SRV-STDA    TO TI-CF06-PRGNOM        13270100
                                                  WS-PROGRAM            13270200
                      MOVE CA-ST-TXT-RET   TO TI-CF06-TXTMSG            13270300
                                              WS-MENSAJE-TXT-EVE        13270400
                                                                        13270500
                      PERFORM 1340-ACTUALIZA-COMAREA                    13270600
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   13270700
                      PERFORM 6000-FINAL                                13270800
                   WHEN WS-CT-ST0404                                    13271000
      *               OBTENER MENSAJE PARA CCE                          13351000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  13352000
                                                                        13353000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              13354000
                      SET  TI-CF06-88-RECH         TO TRUE              13355000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13356000
                                              WS-TEMP-XX                13357000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13358000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1006      TO TI-CF06-COD-RESP-AMPLIADO 13359000
                                              WS-CODMSG-ESTRUCTURA(3: 4)13359100
                      MOVE WS-CT-1006N     TO WS-CT-NUMER               13359200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13359300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      13359400
                                                                        13359500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 13359600
                                                                        13359700
      *               OBTENER MENSAJE INTERNO                           13359800
                      MOVE CA-ST-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    13359900
                                              WS-COD-ERROR-07           13360000
                      MOVE TI-CW03-SRV-STDA    TO TI-CF06-PRGNOM        13360100
                                                  WS-PROGRAM            13360200
                      MOVE CA-ST-TXT-RET   TO TI-CF06-TXTMSG            13360300
                                              WS-MENSAJE-TXT-EVE        13360400
                                                                        13360500
                      PERFORM 1340-ACTUALIZA-COMAREA                    13360600
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   13360700
                      PERFORM 6000-FINAL                                13360800
                   WHEN WS-CT-ST0604                                    13361000
      *               OBTENER MENSAJE PARA CCE                          13441000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  13442000
                                                                        13443000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              13444000
                      SET  TI-CF06-88-RECH         TO TRUE              13445000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13446000
                                              WS-TEMP-XX                13447000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13448000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1001      TO TI-CF06-COD-RESP-AMPLIADO 13449000
                                              WS-CODMSG-ESTRUCTURA(3: 4)13449100
                      MOVE WS-CT-1001N     TO WS-CT-NUMER               13449200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13449300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      13449400
                                                                        13449500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 13449600
                                                                        13449700
      *               OBTENER MENSAJE INTERNO                           13449800
                      MOVE CA-ST-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    13449900
                                              WS-COD-ERROR-07           13450000
                      MOVE TI-CW03-SRV-STDA    TO TI-CF06-PRGNOM        13450100
                                                  WS-PROGRAM            13450200
                      MOVE CA-ST-TXT-RET   TO TI-CF06-TXTMSG            13450300
                                              WS-MENSAJE-TXT-EVE        13450400
                                                                        13450500
                      PERFORM 1340-ACTUALIZA-COMAREA                    13450600
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   13450700
                      PERFORM 6000-FINAL                                13450800
                   WHEN OTHER                                           13451000
      *               OBTENER MENSAJE PARA CCE                          13571000
                      MOVE SPACES              TO TI-CA15-I-O-MENSAJES  13572000
                                                                        13573000
                      SET  TI-CA15-I-RC-APP-CCE    TO TRUE              13574000
                      SET  TI-CF06-88-RECH         TO TRUE              13575000
                      MOVE WS-CT-05        TO TI-CF06-RESPONSE-CODE-CCE 13576000
                                              WS-TEMP-XX                13577000
                                              WS-CODMSG-ESTRUCTURA(1: 2)13578000
                                              TI-TR02-RESPONSE-CODE-CCE         
                      MOVE WS-CT-1021      TO TI-CF06-COD-RESP-AMPLIADO 13579000
                                              WS-CODMSG-ESTRUCTURA(3: 4)13579100
                      MOVE WS-CT-1021N     TO WS-CT-NUMER               13579200
                                              TI-TR02-COD-RESP-AMPLIADO         
                      MOVE WS-CT-001       TO TI-CF06-ORIGEN-RESPUESTA  13579300
                                              TI-TR02-ORIGEN-RESPUESTA          
                      PERFORM 6100-OBTENER-MENSAJE                      13579400
                                                                        13579500
                      MOVE WS-MENSAJE-TXT  TO TI-CF06-MENSAJE-RESPUESTA 13579600
                                                                        13579700
      *               OBTENER MENSAJE INTERNO                           13579800
                      MOVE CA-ST-COD-RET   TO TI-CF06-CODMSG-ESTRUCT    13579900
                                              WS-COD-ERROR-07           13580000
                      MOVE TI-CW03-SRV-STDA    TO TI-CF06-PRGNOM        13580100
                                                  WS-PROGRAM            13580200
                      MOVE CA-ST-TXT-RET   TO TI-CF06-TXTMSG            13580300
                                              WS-MENSAJE-TXT-EVE        13580400
                      PERFORM 1340-ACTUALIZA-COMAREA                    13580500
                      PERFORM 1360-GRABAR-LOG-EVENTOS                   13580600
                      PERFORM 6000-FINAL                                13580700
                 END-EVALUATE                                           13581000
              END-IF                                                    13590000
              .                                                         13590100
      ************************ FIN DE 3200-CUENTA-SAVING                13591000
      *************************                                         13930000
       3400-PAGO-A-CUENTA-TCRE.                                         13940000
      *************************                                         13941000
      ******************************************************************13942000
      * PAGO-A-CUENTA-TCRE - VERIFICAR COPY                            *13960000
      ******************************************************************13970000
      *                                                                 13980000
           INITIALIZE VP-AREA-DATOS-N                                   14040000
                      RG-CA10-I-INPUT-CANAL-HEADER                      14050000
                      RG-CA10-O-OUTPUT-CANAL-HEADER.                    14060000
           MOVE 'VP28'                     TO RG-CA10-I-COD-INTERFAZ    14070000
           MOVE 'A'                        TO RG-CA10-I-CANAL-TIPO      14080000
           MOVE 'P'                        TO RG-CA10-I-CANAL-INST      14090000
           MOVE '1'                        TO RG-CA10-I-COD-INSTITUCION 14100000
           MOVE 'TI'                       TO RG-CA10-I-CANAL-APL       14110000
           MOVE RG-CA05-O-0A-AMBIENTE      TO RG-CA10-I-CANAL-AMB       14120000
           MOVE ZEROS                      TO WS-NRO-OPERACION          14120100
           MOVE TI-TR02-AUTORIZAT-ID-RESP  TO WS-NRO-OPERACION(3:6)     14120200
           MOVE WS-NRO-OPERACION       TO RG-CA10-I-NRO-OPE-CANAL       14120300
           MOVE WS-CT-01               TO RG-CA10-I-VERSION             14120400
           MOVE WS-CT-0                TO RG-CA10-I-FLAG-EXT-OPE        14120500
           MOVE ZEROS                  TO RG-CA10-I-NRO-OPE-CANAL-A-EXT 14120600
           MOVE WS-HORA-INI            TO RG-CA10-I-HORA-CANAL          14121500
           MOVE WS-FECHA-INI           TO RG-CA10-I-FECHA-CANAL         14121600
           MOVE WS-CT-111              TO RG-CA10-I-SUCURSAL-OPERACION  14121800
           MOVE WS-CT-054              TO RG-CA10-I-AGENCIA-OPERACION   14121900
           MOVE WS-CT-1                TO RG-CA10-I-VERSION-HEADER      14122100
           MOVE RG-CA10-I-INPUT-CANAL-HEADER                            14122200
                                           TO RG-CA04-I-HDR-STD-IN      14122300
           MOVE '000'                      TO VP-COM-CODTAR(01:03)      14130000
           MOVE TI-TR02-COD-TARJETA-CRED(2:19) TO VP-COM-CODTAR         14140000
           MOVE 'SL'                       TO VP-COM-TRANSAC            14150000
                                                                        14160000
           PERFORM 4180-ASIGNAR-TERM-USER                               14171000
           MOVE RG-CA04-I-HDR-STD-IN   TO RG-CA10-I-INPUT-CANAL-HEADER  14172000
                                          VP-I-O-HEADER-ESTANDAR        14173000
      *                                                                 14180000
           EXEC CICS LINK PROGRAM  (TI-CW03-SRV-VP28)                   14190000
                          COMMAREA (VP-AREA-DATOS-N)                    14200000
                          LENGTH   (LENGTH OF VP-AREA-DATOS-N)          14210000
                          NOHANDLE                                      14230000
                          RESP(WS-RESP)                                 14240000
           END-EXEC.                                                    14250000
      *                                                                 14260000
           IF WS-RESP NOT EQUAL DFHRESP(NORMAL)                         14261000
      *       OBTENER MENSAJE PARA CCE                                  14262000
              MOVE SPACES                 TO TI-CA15-I-O-MENSAJES       14263000
                                                                        14264000
              SET  TI-CA15-I-RC-APP-CCE   TO TRUE                       14265000
              SET  TI-CF06-88-RECH        TO TRUE                       14266000
              MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE  14267000
                                             WS-TEMP-XX                 14268000
                                             WS-CODMSG-ESTRUCTURA(1: 2) 14269000
                                             TI-TR02-RESPONSE-CODE-CCE          
              MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO  14269100
                                             WS-CODMSG-ESTRUCTURA(3: 4) 14269200
              MOVE WS-CT-1021N            TO WS-CT-NUMER                14269300
                                             TI-TR02-COD-RESP-AMPLIADO          
              MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA   14269400
                                             TI-TR02-ORIGEN-RESPUESTA           
              PERFORM 6100-OBTENER-MENSAJE                              14269500
                                                                        14269600
              MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA  14269700
              PERFORM 1340-ACTUALIZA-COMAREA                            14269800
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
              MOVE TI-CW03-SRV-VP28       TO WS-VARMSG-RSO              14270900
                                                                        14271000
              PERFORM 6100-OBTENER-MENSAJE                              14271100
              MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG             14271200
                                             WS-MENSAJE-TXT-EVE         14271300
                                                                        14271400
              PERFORM 1360-GRABAR-LOG-EVENTOS                           14271500
              PERFORM 6000-FINAL                                        14271600
           END-IF                                                       14271700
                                                                        14271800
           MOVE VP-I-O-HEADER-ESTANDAR TO RG-CA10-O-OUTPUT-CANAL-HEADER 14272000
                                                                        14280000
           IF (RG-CA10-O-RC-TIP = WS-CT-00 AND                          14290000
               RG-CA10-O-RC-SEC = WS-CT-00)                             14300000
               MOVE VP-CODBLQ              TO WS-BLQ-VP28               00160022
               IF  WS-BLQ-VP28-ERR                                      00160022
      *            OBTENER MENSAJE PARA CCE                             00160022
                   MOVE SPACES         TO TI-CA15-I-O-MENSAJES          00160022
                                                                        00160022
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  00160022
                   SET  TI-CF06-88-RECH        TO TRUE                  00160022
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 00160022
                                              WS-TEMP-XX                00160022
                                              WS-CODMSG-ESTRUCTURA(1: 2)00160022
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1001         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)00160022
                   MOVE WS-CT-1001N        TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  00160022
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         00160022
                                                                        00160022
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 00160022
                                                                        00160022
      *            OBTENER MENSAJE INTERNO                              00160022
                   MOVE WS-CODMSG-ESTRUCTURA                            00160022
                                           TO WS-COD-ERROR-07           00160022
                   MOVE WS-PROGRAM-ID      TO WS-PROGRAM                00160022
                                                                        00160022
                   MOVE WS-MENSAJE-TXT     TO WS-MENSAJE-TXT-EVE        00160022
                                                                        00160022
                                                                        00160022
                   PERFORM 1340-ACTUALIZA-COMAREA                       00160022
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      00160022
                   PERFORM 6000-FINAL                                   00160022
                                                                        00160022
               END-IF                                                   00160022
                                                                        00160022
               IF VP-FBINMON = 'N'                                      14310000
                  EVALUATE VP-COD-MON-DUAL                              14320000
                  WHEN WS-CT-0001                                       14330000
                     IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-604       14340000
      *                 OBTENER MENSAJE PARA CCE                        14461000
                        MOVE SPACES        TO TI-CA15-I-O-MENSAJES      14462000
                                                                        14463000
                        SET  TI-CA15-I-RC-APP-CCE  TO TRUE              14464000
                        SET  TI-CF06-88-RECH       TO TRUE              14465000
                        MOVE WS-CT-05      TO TI-CF06-RESPONSE-CODE-CCE 14466000
                                              WS-TEMP-XX                14467000
                                              WS-CODMSG-ESTRUCTURA(1: 2)14468000
                                              TI-TR02-RESPONSE-CODE-CCE         
                        MOVE WS-CT-1009    TO TI-CF06-COD-RESP-AMPLIADO 14469000
                                              WS-CODMSG-ESTRUCTURA(3: 4)14469100
                        MOVE WS-CT-1009N   TO WS-CT-NUMER               14469200
                                              TI-TR02-COD-RESP-AMPLIADO         
                        MOVE WS-CT-001     TO TI-CF06-ORIGEN-RESPUESTA  14469300
                                              TI-TR02-ORIGEN-RESPUESTA          
                        PERFORM 6100-OBTENER-MENSAJE                    14469400
                                                                        14469500
                        MOVE WS-MENSAJE-TXT                             14469600
                                           TO TI-CF06-MENSAJE-RESPUESTA 14469700
                                                                        14469800
      *                 OBTENER MENSAJE INTERNO                         14469900
                        MOVE WS-CODMSG-ESTRUCTURA                       14470000
                                           TO WS-COD-ERROR-07           14470100
                        MOVE WS-PROGRAM-ID TO WS-PROGRAM                14470200
                                                                        14470300
                        MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE    14470400
                                                                        14470500
                                                                        14470600
                        PERFORM 1340-ACTUALIZA-COMAREA                  14470700
                        PERFORM 1360-GRABAR-LOG-EVENTOS                 14470800
                        PERFORM 6000-FINAL                              14470900
                     END-IF                                             14471000
      *                                                                 14480000
                  WHEN WS-CT-1001                                       14490000
                     IF TI-TR02-TRANS-CURREN-CODE NOT = WS-CT-840       14500000
      *                 OBTENER MENSAJE PARA CCE                        14581000
                        MOVE SPACES        TO TI-CA15-I-O-MENSAJES      14582000
                                                                        14583000
                        SET  TI-CA15-I-RC-APP-CCE  TO TRUE              14584000
                        SET  TI-CF06-88-RECH       TO TRUE              14585000
                        MOVE WS-CT-05      TO TI-CF06-RESPONSE-CODE-CCE 14586000
                                              WS-TEMP-XX                14587000
                                              WS-CODMSG-ESTRUCTURA(1: 2)14588000
                                              TI-TR02-RESPONSE-CODE-CCE         
                        MOVE WS-CT-1009    TO TI-CF06-COD-RESP-AMPLIADO 14589000
                                              WS-CODMSG-ESTRUCTURA(3: 4)14589100
                        MOVE WS-CT-1009N   TO WS-CT-NUMER               14589200
                                              TI-TR02-COD-RESP-AMPLIADO         
                        MOVE WS-CT-001     TO TI-CF06-ORIGEN-RESPUESTA  14589300
                                              TI-TR02-ORIGEN-RESPUESTA          
                        PERFORM 6100-OBTENER-MENSAJE                    14589400
                                                                        14589500
                        MOVE WS-MENSAJE-TXT                             14589600
                                           TO TI-CF06-MENSAJE-RESPUESTA 14589700
                                                                        14589800
      *                 OBTENER MENSAJE INTERNO                         14589900
                        MOVE WS-CODMSG-ESTRUCTURA                       14590000
                                           TO WS-COD-ERROR-07           14590100
                        MOVE WS-PROGRAM-ID TO WS-PROGRAM                14590200
                                                                        14590300
                        MOVE WS-MENSAJE-TXT    TO WS-MENSAJE-TXT-EVE    14590400
                                                                        14590500
                                                                        14590600
                        PERFORM 1340-ACTUALIZA-COMAREA                  14590700
                        PERFORM 1360-GRABAR-LOG-EVENTOS                 14590800
                        PERFORM 6000-FINAL                              14590900
                     END-IF                                             14591000
      *                                                                 14600000
                  WHEN OTHER                                            14610000
      *              OBTENER MENSAJE PARA CCE                           14691000
                     MOVE SPACES           TO TI-CA15-I-O-MENSAJES      14692000
                                                                        14693000
                     SET  TI-CA15-I-RC-APP-CCE     TO TRUE              14694000
                     SET  TI-CF06-88-RECH          TO TRUE              14695000
                     MOVE WS-CT-05         TO TI-CF06-RESPONSE-CODE-CCE 14696000
                                              WS-TEMP-XX                14697000
                                              WS-CODMSG-ESTRUCTURA(1: 2)14698000
                                              TI-TR02-RESPONSE-CODE-CCE         
                     MOVE WS-CT-1009       TO TI-CF06-COD-RESP-AMPLIADO 14699000
                                              WS-CODMSG-ESTRUCTURA(3: 4)14699100
                     MOVE WS-CT-1009N      TO WS-CT-NUMER               14699200
                                              TI-TR02-COD-RESP-AMPLIADO         
                     MOVE WS-CT-001        TO TI-CF06-ORIGEN-RESPUESTA  14699300
                                              TI-TR02-ORIGEN-RESPUESTA          
                     PERFORM 6100-OBTENER-MENSAJE                       14699400
                                                                        14699500
                     MOVE WS-MENSAJE-TXT                                14699600
                                           TO TI-CF06-MENSAJE-RESPUESTA 14699700
                                                                        14699800
      *              OBTENER MENSAJE INTERNO                            14699900
                     MOVE WS-CODMSG-ESTRUCTURA                          14700000
                                           TO WS-COD-ERROR-07           14700100
                     MOVE WS-PROGRAM-ID    TO WS-PROGRAM                14700200
                                                                        14700300
                     MOVE WS-MENSAJE-TXT   TO WS-MENSAJE-TXT-EVE        14700400
                                                                        14700500
                                                                        14700600
                     PERFORM 1340-ACTUALIZA-COMAREA                     14700700
                     PERFORM 1360-GRABAR-LOG-EVENTOS                    14700800
                     PERFORM 6000-FINAL                                 14700900
                  END-EVALUATE                                          14701000
               END-IF                                                   14710000
      *                                                                 14720000
               INITIALIZE SGCWGDGC                                      14730000
                  REPLACING                                             14740000
                     NUMERIC DATA BY ZEROES                             14750000
                     ALPHANUMERIC DATA BY SPACES                        14760000
      *                                                                 14770000
               MOVE '4'                      TO DGC-IND-CLAVE           14780000
               MOVE 'TCR'                    TO DGC-GLS-SERVICIO        14790000
                                                                        14800000
               IF  VP-TIPO-PROD = 'A'                                   14810000
                   MOVE TI-TR02-COD-TARJETA-CRED(6:15)                  14821000
                                             TO DGC-GLS-CLAVE(1:15)     14822000
                   MOVE '0'                  TO DGC-GLS-CLAVE(16:1)     14823000
                                                                        14830000
               ELSE                                                     14840000
                   MOVE TI-TR02-COD-TARJETA-CRED(5:16)                  14861000
                                             TO DGC-GLS-CLAVE(1:16)     14862000
               END-IF                                                   14863000
                                                                        14864000
               MOVE TI-TR02-TIP-DOC-CLI-ORIG TO WS-TIPO-DOC-ORD-HOMOL   14870000
               PERFORM 4155-HOMOLOGA-DOC                                14880000
               MOVE WS-TIPO-DOC-ORD-HOMOL    TO TI-CF06-TIP-DOC-CLI-ORIG14881000
      *                                                                 14890000
               PERFORM 3500-VALIDAR-DOCUM-TCRE                          14891000
               MOVE WS-CT-O                TO TI-TR02-INDI-MISMO-CLIENTE14891100
      *                                                                 14892000
           ELSE                                                         15320000
      *        OBTENER MENSAJE PARA CCE                                 15401000
               MOVE SPACES             TO TI-CA15-I-O-MENSAJES          15402000
                                                                        15403000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      15404000
               SET  TI-CF06-88-RECH        TO TRUE                      15405000
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     15406000
                                          WS-TEMP-XX                    15407000
                                          WS-CODMSG-ESTRUCTURA(1: 2)    15408000
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO     15409000
                                          WS-CODMSG-ESTRUCTURA(3: 4)    15409100
               MOVE WS-CT-1002N        TO WS-CT-NUMER                   15409200
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      15409300
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             15409400
                                                                        15409500
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     15409600
                                                                        15409700
      *        OBTENER MENSAJE INTERNO                                  15409800
               MOVE RG-CA10-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT        15409900
                                          WS-COD-ERROR-07               15410000
               MOVE TI-CW03-SRV-VP28   TO TI-CF06-PRGNOM                15410100
                                          WS-PROGRAM                    15410200
               MOVE RG-CA10-O-RC-MSG   TO TI-CF06-TXTMSG                15410300
                                          WS-MENSAJE-TXT-EVE            15410400
               PERFORM 1340-ACTUALIZA-COMAREA                           15410500
               PERFORM 1360-GRABAR-LOG-EVENTOS                          15410600
               PERFORM 6000-FINAL                                       15410700
           END-IF                                                       15411000
           .                                                            15412000
      ************************ FIN DE 3400-PAGO-A-CUENTA-TCRE           15420000
      *************************                                         15420100
       3500-VALIDAR-DOCUM-TCRE.                                         15420200
      *************************                                         15420300
      *                                                                 15420700
           EXEC CICS LINK                                               15420800
                     PROGRAM (WS-RTN-SGCPPDGC)                          15420900
                     COMMAREA(SGCWGDGC)                                 15421000
                     LENGTH  (LENGTH OF SGCWGDGC)                       15421100
                     RESP    (WS-RESP)                                  15421200
           END-EXEC                                                     15421300
      *                                                                 15421400
           IF DGC-CRETORNO(1) = WS-CT-0000                              15421500
              MOVE WS-CT-1N  TO IND                                     15421600
      *                                                                 15421700
              PERFORM UNTIL IND > WS-CT-5N OR                           15421800
                      DGC-NUM-ICLI(IND) = SPACES                        15421900
                PERFORM 3700-FORMATEAR-DOCUMENTO                        15422000
                                                                        15422100
                EVALUATE WS-TIPO-DOC-ORD-HOMOL                          15423700
                  WHEN "6"                                              15423800
                      IF DGC-COD-IRUC(IND)  =                           15423900
                                          TI-TR02-NRO-DOC-CLI-ORIG(1:11)15424000
                         MOVE IND          TO INDOK                     15424100
                         MOVE WS-CT-6N     TO IND                       15424200
                         MOVE 1            TO WS-CUENTA-PROPIA-SI       15424300
                      END-IF                                            15424400
                                                                        15424500
                  WHEN "3"                                              15424600
                  WHEN "4"                                              15424700
                      MOVE SPACES              TO WS-DOC-ORD-TMP        15424800
                      MOVE DGC-NUM-ICLI(IND)   TO WS-DOC-ORD-TMP        15424900
                      PERFORM 5000-REORDENAR-DOCUMENTO                  15425000
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CONSIST    15425100
                                                                        15425200
                      MOVE SPACES              TO WS-DOC-ORD-TMP        15425300
                      MOVE TI-TR02-NRO-DOC-CLI-ORIG                     15425400
                                               TO WS-DOC-ORD-TMP        15425500
                      PERFORM 5000-REORDENAR-DOCUMENTO                  15425600
                      MOVE WS-DOC-ORD-TMP2     TO WS-DOC-ORD-CCE        15425700
                                                                        15425800
                      IF WS-DOC-ORD-CONSIST(5: 8) = WS-DOC-ORD-CCE(5:8) 15425900
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  15426000
                         MOVE IND                TO INDOK               15426100
                         MOVE WS-CT-6N           TO IND                 15426200
                         MOVE 1                  TO WS-CUENTA-PROPIA-SI 15426300
                                                                        15426400
                      END-IF                                            15426500
                                                                        15426600
                  WHEN OTHER                                            15426700
                      IF DGC-NUM-ICLI(IND) =                            15426800
                                           TI-TR02-NRO-DOC-CLI-ORIG(1:8)15426900
                         AND DGC-IND-ICLI(IND) = WS-TIPO-DOC-ORD-HOMOL  15427000
                         MOVE IND                TO INDOK               15427100
                         MOVE WS-CT-6N           TO IND                 15427200
                         MOVE 1                  TO WS-CUENTA-PROPIA-SI 15427300
                      END-IF                                            15427400
                                                                        15427500
                END-EVALUATE                                            15427600
      *                                                                 15427700
                COMPUTE IND = IND + 1                                   15427800
                END-COMPUTE                                             15427900
              END-PERFORM                                               15428000
      *                                                                 15428100
              IF WS-TIPO-DOC-ORD-HOMOL = WS-CT-6                        15428200
                 IF WS-CUENTA-PROPIA-SI = 1                             15428300
                    INSPECT DGC-GLS-NOMC(INDOK) CONVERTING              15428400
                                 WS-FINDREPLACE TO WS-REPLACE           15428500
                    MOVE DGC-GLS-NOMC(INDOK) TO TI-TR02-APE-PAT-CLI-BENE15428600
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           15428700
                    STRING WS-CT-SPACE4                                 15428800
                      DGC-NUM-ICLI(INDOK)                               15428900
                      DGC-IND-ICLI(INDOK)                               15429000
                      DGC-GLS-ICLI(INDOK)                               15429100
                      DELIMITED BY SIZE INTO WS-IDC                     15429200
                    END-STRING                                          15429300
                    MOVE WS-CT-M TO TI-TR02-INDI-MISMO-CLIENTE          15429400
                 ELSE                                                   15429500
                    INSPECT DGC-GLS-NOMC(1) CONVERTING                  15429600
                                 WS-FINDREPLACE TO WS-REPLACE           15429700
                    MOVE DGC-GLS-NOMC(1) TO TI-TR02-APE-PAT-CLI-BENE    15429800
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           15429900
                    STRING WS-CT-SPACE4                                 15430000
                       DGC-NUM-ICLI(1)                                  15430100
                       DGC-IND-ICLI(1)                                  15430200
                       DGC-GLS-ICLI(1)                                  15430300
                       DELIMITED BY SIZE INTO WS-IDC                    15430400
                    END-STRING                                          15430500
                    MOVE WS-CT-O   TO TI-TR02-INDI-MISMO-CLIENTE        15430600
                 END-IF                                                 15430700
              ELSE                                                      15430800
                 IF WS-CUENTA-PROPIA-SI = 1                             15430900
                    INSPECT DGC-GLS-APAT(INDOK) CONVERTING              15431000
                                 WS-FINDREPLACE TO WS-REPLACE           15431100
                    MOVE DGC-GLS-APAT(INDOK) TO TI-TR02-APE-PAT-CLI-BENE15431200
                    INSPECT DGC-GLS-AMAT(INDOK) CONVERTING              15431300
                                 WS-FINDREPLACE TO WS-REPLACE           15431400
                    MOVE DGC-GLS-AMAT(INDOK) TO TI-TR02-APE-MAT-CLI-BENE15431500
                    INSPECT DGC-GLS-NOMB(INDOK) CONVERTING              15431600
                                 WS-FINDREPLACE TO WS-REPLACE           15431700
                    MOVE DGC-GLS-NOMB(INDOK) TO TI-TR02-NOMBRE-CLI-BENE 15431800
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           15431900
                    STRING WS-CT-SPACE4                                 15432000
                         DGC-NUM-ICLI(INDOK)                            15432100
                         DGC-IND-ICLI(INDOK)                            15432200
                         DGC-GLS-ICLI(INDOK)                            15432300
                         DELIMITED BY SIZE INTO WS-IDC                  15432400
                    END-STRING                                          15432500
                    MOVE WS-CT-M           TO TI-TR02-INDI-MISMO-CLIENTE15432600
                 ELSE                                                   15432700
                    INSPECT DGC-GLS-APAT(1) CONVERTING                  15432800
                                 WS-FINDREPLACE TO WS-REPLACE           15432900
                    MOVE DGC-GLS-APAT(1)   TO TI-TR02-APE-PAT-CLI-BENE  15433000
                    INSPECT DGC-GLS-AMAT(1) CONVERTING                  15433100
                                 WS-FINDREPLACE TO WS-REPLACE           15433200
                    MOVE DGC-GLS-AMAT(1)   TO TI-TR02-APE-MAT-CLI-BENE  15433300
                    INSPECT DGC-GLS-NOMB(1) CONVERTING                  15433400
                                 WS-FINDREPLACE TO WS-REPLACE           15433500
                    MOVE DGC-GLS-NOMB(1)   TO TI-TR02-NOMBRE-CLI-BENE   15433600
      *LA VARIABLE WS-IDC ES DE 16 CARACTERES                           15433700
                    STRING WS-CT-SPACE4                                 15433800
                         DGC-NUM-ICLI(1)                                15433900
                         DGC-IND-ICLI(1)                                15434000
                         DGC-GLS-ICLI(1)                                15434100
                         DELIMITED BY SIZE INTO WS-IDC                  15434200
                     END-STRING                                         15434300
                     MOVE WS-CT-O          TO TI-TR02-INDI-MISMO-CLIENTE15434400
                  END-IF                                                15434500
              END-IF                                                    15434600
      *                                                                 15434700
           ELSE                                                         15434800
              IF  (WS-CT-0001 = DGC-CRETORNO(1) OR                      15434900
                   WS-CT-0002 = DGC-CRETORNO(1) OR                      15435000
                   WS-CT-0003 = DGC-CRETORNO(1) OR                      15435100
                   WS-CT-0009 = DGC-CRETORNO(1) )                       15435200
      *            OBTENER MENSAJE PARA CCE                             15435300
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  15435400
                                                                        15435500
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  15435600
                   SET  TI-CF06-88-RECH        TO TRUE                  15435700
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 15435800
                                              WS-TEMP-XX                15435900
                                              WS-CODMSG-ESTRUCTURA(1: 2)15436000
                                              TI-TR02-RESPONSE-CODE-CCE         
      *            MOVE WS-CT-1007         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                   MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO 00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)15436200
      *            MOVE WS-CT-1007N        TO WS-CT-NUMER               00160022
                   MOVE WS-CT-1006N        TO WS-CT-NUMER               00160022
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  15436400
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         15436500
                                                                        15436600
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 15436700
                                                                        15436800
      *            OBTENER MENSAJE INTERNO                              15436900
                   MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT    15437000
                                              WS-COD-ERROR-07           15437100
                   MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM            15437200
                                              WS-PROGRAM                15437300
                   MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG            15437400
                                              WS-MENSAJE-TXT-EVE        15437500
                                                                        15437600
                   PERFORM 1340-ACTUALIZA-COMAREA                       15437700
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      15437800
                   PERFORM 6000-FINAL                                   15437900
              ELSE                                                      15438000
                IF (WS-CT-2002 = DGC-CRETORNO(1) OR                     15438100
                    WS-CT-2008 = DGC-CRETORNO(1) )                      15438200
      *             OBTENER MENSAJE PARA CCE                            15438300
                    MOVE SPACES                 TO TI-CA15-I-O-MENSAJES 15438400
                                                                        15438500
                    SET  TI-CA15-I-RC-APP-CCE   TO TRUE                 15438600
                    SET  TI-CF06-88-RECH        TO TRUE                 15438700
                    MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE15438800
                                              WS-TEMP-XX                15438900
                                              WS-CODMSG-ESTRUCTURA(1: 2)15439000
                                              TI-TR02-RESPONSE-CODE-CCE         
                    MOVE WS-CT-1002         TO TI-CF06-COD-RESP-AMPLIADO15439100
                                              WS-CODMSG-ESTRUCTURA(3: 4)15439200
                    MOVE WS-CT-1002N        TO WS-CT-NUMER              15439300
                                               TI-TR02-COD-RESP-AMPLIADO        
                    MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA 15439400
                                               TI-TR02-ORIGEN-RESPUESTA         
                    PERFORM 6100-OBTENER-MENSAJE                        15439500
                                                                        15439600
                    MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA15439700
                                                                        15439800
      *             OBTENER MENSAJE INTERNO                             15439900
                    MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT   15440000
                                               WS-COD-ERROR-07          15440100
                    MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM           15440200
                                               WS-PROGRAM               15440300
                    MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG           15440400
                                               WS-MENSAJE-TXT-EVE       15440500
                                                                        15440600
                    PERFORM 1340-ACTUALIZA-COMAREA                      15440700
                    PERFORM 1360-GRABAR-LOG-EVENTOS                     15440800
                    PERFORM 6000-FINAL                                  15440900
                ELSE                                                    15441000
      *             OBTENER MENSAJE PARA CCE                            15441100
                    MOVE SPACES                 TO TI-CA15-I-O-MENSAJES 15441200
                                                                        15441300
                    SET  TI-CA15-I-RC-APP-CCE   TO TRUE                 15441400
                    SET  TI-CF06-88-RECH        TO TRUE                 15441500
                    MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE15441600
                                              WS-TEMP-XX                15441700
                                              WS-CODMSG-ESTRUCTURA(1: 2)15441800
                                              TI-TR02-RESPONSE-CODE-CCE         
      *             MOVE WS-CT-1008         TO TI-CF06-COD-RESP-AMPLIADO00160022
                    MOVE WS-CT-1006         TO TI-CF06-COD-RESP-AMPLIADO00160022
                                              WS-CODMSG-ESTRUCTURA(3: 4)15442000
      *             MOVE WS-CT-1008N        TO WS-CT-NUMER              00160022
                    MOVE WS-CT-1006N        TO WS-CT-NUMER              00160022
                                               TI-TR02-COD-RESP-AMPLIADO        
                    MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA 15442200
                                               TI-TR02-ORIGEN-RESPUESTA         
                    PERFORM 6100-OBTENER-MENSAJE                        15442300
                                                                        15442400
                    MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA15442500
                                                                        15442600
      *             OBTENER MENSAJE INTERNO                             15442700
                    MOVE DGC-CRETORNO(1)    TO TI-CF06-CODMSG-ESTRUCT   15442800
                                               WS-COD-ERROR-07          15442900
                    MOVE WS-RTN-SGCPPDGC    TO TI-CF06-PRGNOM           15443000
                                               WS-PROGRAM               15443100
                    MOVE DGC-MSG-ERROR(1)   TO TI-CF06-TXTMSG           15443200
                                               WS-MENSAJE-TXT-EVE       15443300
                                                                        15443400
                    PERFORM 1340-ACTUALIZA-COMAREA                      15443500
                    PERFORM 1360-GRABAR-LOG-EVENTOS                     15443600
                    PERFORM 6000-FINAL                                  15443700
               END-IF                                                   15443800
           END-IF                                                       15443900
           .                                                            15444000
      ************************ FIN DE 3500-VALIDAR-DOCUM-TCRE           15444100
      **************************                                        15444200
       3700-FORMATEAR-DOCUMENTO.                                        15444300
      **************************                                        15444400
      ******************************************************************15445000
      * INVOCAR RUTINA SGCPPDGC - VERIFICAR COPY                       *15450000
      ******************************************************************15451000
                                                                        15470000
           PERFORM 3750-VALIDA-CARACTERES.                              15480000
      ************************ FIN DE 3700-FORMATEAR-DOCUMENTO          15490000
      ************************                                          15491000
       3750-VALIDA-CARACTERES.                                          15500000
      ************************                                          15510000
           MOVE DGC-NUM-ICLI(IND)   TO WS-NROCLI-CONSIS-WORK            15520000
           MOVE SPACES              TO WS-NROCLI-CONSIS-WORK1           15530000
           MOVE 0                   TO WS-J WS-K                        15540000
           PERFORM 8 TIMES                                              15550000
               ADD 1                 TO WS-J                            15560000
               MOVE WS-NROCLI-CONSIS-WORK (WS-J:1) TO WS-VALIDO         15570000
               IF  WS-VALIDO-NUM OR WS-VALIDO-ALF                       15580000
                   ADD 1              TO WS-K                           15590000
                   MOVE WS-NROCLI-CONSIS-WORK(WS-J:1)                   15600000
                                      TO WS-NROCLI-CONSIS-WORK1(WS-K:1) 15610000
               ELSE                                                     15620000
                   CONTINUE                                             15630000
               END-IF                                                   15640000
           END-PERFORM                                                  15650000
           MOVE WS-NROCLI-CONSIS-WORK1 TO DGC-NUM-ICLI(IND)             15660000
           .                                                            15660100
      ************************ FIN DE 3750-VALIDA-CARACTERES            15661000
      *****************                                                 16070000
       4150-BUSCAR-MON.                                                 16080000
      *****************                                                 16090000
           MOVE SPACES     TO TI-CF01-KEY03                             16100000
           MOVE WS-CT-03   TO TI-CF01-KEY03-TIP-PRM                     16110000
           MOVE WS-CT-10C  TO TI-CF01-KEY03-CTABL                       16120000
           MOVE TI-TR02-TRANS-CURREN-CODE                               16130000
                           TO TI-CF01-KEY03-DTABL                       16140000
           EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              16150000
                INTO(TI-CF01-REG-PARAMETROS)                            16160000
                LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)                16170000
                RIDFLD(TI-CF01-KEY03)                                   16180000
                KEYLENGTH(LENGTH OF TI-CF01-KEY03)                      16190000
                RESP(WS-RESP)                                           16200000
           END-EXEC                                                     16210000
                                                                        16220000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        16230000
               MOVE WS-RESP                TO WS-RESP-TXT               16240000
      *        OBTENER MENSAJE PARA CCE                                 16291000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16292000
                                                                        16293000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      16294000
               SET  TI-CF06-88-RECH        TO TRUE                      16295000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 16296000
                                              WS-TEMP-XX                16297000
                                              WS-CODMSG-ESTRUCTURA(1: 2)16298000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 16299000
                                              WS-CODMSG-ESTRUCTURA(3: 4)16299100
               MOVE WS-CT-1021N            TO WS-CT-NUMER               16299200
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  16299300
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             16299400
                                                                        16299500
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 16299600
               PERFORM 1340-ACTUALIZA-COMAREA                           16299700
                                                                        16299800
      *        OBTENER MENSAJE INTERNO                                  16299900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16300000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      16300100
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    16300200
                                              WS-CODMSG-ESTRUCTURA      16300300
                                              WS-COD-ERROR-07           16300400
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            16300500
                                              WS-PROGRAM                16300600
               MOVE TI-CW03-FILE-PARAMETROS                             16300700
                                           TO WS-VARMSG-RSO             16300800
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             16300900
                                                                        16301000
               PERFORM 6100-OBTENER-MENSAJE                             16301100
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            16301200
                                              WS-MENSAJE-TXT-EVE        16301300
                                                                        16301400
               PERFORM 1360-GRABAR-LOG-EVENTOS                          16301500
               PERFORM 6000-FINAL                                       16301600
           ELSE                                                         16302000
               MOVE TI-CF01-DTBL-VALOR(1:4)    TO TI-CF06-COD-MON       16310000
           END-IF                                                       16320000
           .                                                            16321000
      ************************ FIN DE 4150-BUSCAR-MON                   16330000
      *******************                                               16331000
       4155-HOMOLOGA-DOC.                                               16340000
      *******************                                               16350000
           MOVE SPACES                     TO TI-CF01-KEY03             16360000
           MOVE WS-CT-03                   TO TI-CF01-KEY03-TIP-PRM     16370000
           MOVE WS-CT-08C                  TO TI-CF01-KEY03-CTABL       16380000
           MOVE WS-TIPO-DOC-ORD-HOMOL      TO TI-CF01-KEY03-DTABL       16391000
      *                                                                 16400000
           EXEC CICS READ DATASET(TI-CW03-FILE-PARAMETROS)              16410000
                INTO(TI-CF01-REG-PARAMETROS)                            16420000
                LENGTH(LENGTH OF TI-CF01-REG-PARAMETROS)                16430000
                RIDFLD(TI-CF01-KEY03)                                   16440000
                KEYLENGTH(LENGTH OF TI-CF01-KEY03)                      16450000
                RESP(WS-RESP)                                           16460000
           END-EXEC                                                     16470000
                                                                        16480000
           IF  WS-RESP NOT EQUAL DFHRESP(NORMAL)                        16490000
               MOVE WS-RESP                TO WS-RESP-TXT               16500000
      *        OBTENER MENSAJE PARA CCE                                 16551000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16552000
                                                                        16553000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      16554000
               SET  TI-CF06-88-RECH        TO TRUE                      16555000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 16556000
                                              WS-TEMP-XX                16557000
                                              WS-CODMSG-ESTRUCTURA(1: 2)16558000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 16559000
                                              WS-CODMSG-ESTRUCTURA(3: 4)16559100
               MOVE WS-CT-1021N            TO WS-CT-NUMER               16559200
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  16559300
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             16559400
                                                                        16559500
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 16559600
               PERFORM 1340-ACTUALIZA-COMAREA                           16559700
                                                                        16559800
      *        OBTENER MENSAJE INTERNO                                  16559900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16560000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      16560100
               MOVE 'TI0807'               TO TI-CF06-CODMSG-ESTRUCT    16560200
                                              WS-CODMSG-ESTRUCTURA      16560300
                                              WS-COD-ERROR-07           16560400
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            16560500
                                              WS-PROGRAM                16560600
               MOVE TI-CW03-FILE-PARAMETROS                             16560700
                                           TO WS-VARMSG-RSO             16560800
               MOVE WS-RESP-TXT            TO WS-VARMSG-ARG             16560900
                                                                        16561000
               PERFORM 6100-OBTENER-MENSAJE                             16561100
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            16561200
                                              WS-MENSAJE-TXT-EVE        16561300
                                                                        16561400
               PERFORM 1360-GRABAR-LOG-EVENTOS                          16561500
               PERFORM 6000-FINAL                                       16561600
           ELSE                                                         16562000
               MOVE TI-CF01-DTBL-VALOR(1:1)    TO WS-TIPO-DOC-ORD-HOMOL 16570000
           END-IF                                                       16580000
           .                                                            16580100
      ************************ FIN DE 4155-HOMOLOGA-DOC                 16581000
      ************************                                          16591000
       4180-ASIGNAR-TERM-USER.                                          16600000
      ************************                                          16610000
      *                                                                 16620000
           INITIALIZE  RG-CA04-TETI-USER                                16630000
           REPLACING  ALPHANUMERIC DATA BY SPACES                       16640000
                      NUMERIC DATA BY ZEROS                             16650000
                                                                        16660000
           SET  RG-CA04-88-COMMAREA          TO TRUE                    16670000
           SET  RG-CA04-I-88-ASIGNA          TO TRUE                    16680000
           MOVE RG-CA10-I-INPUT-CANAL-HEADER TO RG-CA04-I-HDR-STD-IN    16690000
                                                                        16700000
                                                                        16710000
           MOVE WS-RTN-ASIGNA-TETI           TO WS-RTN-SGTE             16720000
           MOVE RG-CA04-TETI-USER            TO WS-CCAA                 16730000
           MOVE LENGTH OF RG-CA04-TETI-USER  TO WS-LGTH-CCAA            16740000
           PERFORM  4190-RUT-LINK-GRAL                                  16750000
           MOVE WS-CCAA                      TO RG-CA04-TETI-USER       16760000
                                                                        16760100
           IF  RG-CA04-O-RC-NUM NOT EQUAL WS-CT-0000                    16760200
      *        OBTENER MENSAJE PARA CCE                                 16760300
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16760400
                                                                        16760500
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      16760600
               SET  TI-CF06-88-RECH        TO TRUE                      16760700
               MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE     16760800
                                          WS-TEMP-XX                    16760900
                                          WS-CODMSG-ESTRUCTURA(1: 2)    16761000
                                          TI-TR02-RESPONSE-CODE-CCE             
               MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO     16761100
                                          WS-CODMSG-ESTRUCTURA(3: 4)    16761200
               MOVE WS-CT-1021N        TO WS-CT-NUMER                   16761300
                                          TI-TR02-COD-RESP-AMPLIADO             
               MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA      16761400
                                          TI-TR02-ORIGEN-RESPUESTA              
               PERFORM 6100-OBTENER-MENSAJE                             16761500
                                                                        16761600
               MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA     16761700
                                                                        16761800
      *        OBTENER MENSAJE INTERNO                                  16761900
               MOVE RG-CA04-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT        16762000
                                          WS-COD-ERROR-07               16762100
               MOVE WS-RTN-ASIGNA-TETI TO TI-CF06-PRGNOM                16762200
                                          WS-PROGRAM                    16762300
               MOVE RG-CA04-O-MSG      TO TI-CF06-TXTMSG                16762400
                                          WS-MENSAJE-TXT-EVE            16762500
                                                                        16762600
               PERFORM 1340-ACTUALIZA-COMAREA                           16762700
               PERFORM 1360-GRABAR-LOG-EVENTOS                          16762800
               PERFORM 6000-FINAL                                       16762900
           END-IF                                                       16763000
           .                                                            16764000
      ************************ FIN DE 4180-ASIGNAR-TERM-USER            16770000
      ********************                                              16771000
       4190-RUT-LINK-GRAL.                                              16780000
      ********************                                              16790000
                                                                        16800000
           EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                      16810000
                 COMMAREA (WS-CCAA)                                     16820000
                 LENGTH (WS-LGTH-CCAA)                                  16830000
                 RESP (WS-RESP)                                         16840000
                 RESP2 (WS-RESP2)                                       16850000
           END-EXEC.                                                    16860000
      *                                                                 16870000
           IF  WS-RESP  NOT EQUAL DFHRESP(NORMAL)                       16880000
      *        OBTENER MENSAJE PARA CCE                                 16941000
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16942000
                                                                        16943000
               SET  TI-CA15-I-RC-APP-CCE   TO TRUE                      16944000
               SET  TI-CF06-88-RECH        TO TRUE                      16945000
               MOVE WS-CT-05               TO TI-CF06-RESPONSE-CODE-CCE 16946000
                                              WS-TEMP-XX                16947000
                                              WS-CODMSG-ESTRUCTURA(1: 2)16948000
                                              TI-TR02-RESPONSE-CODE-CCE         
               MOVE WS-CT-1021             TO TI-CF06-COD-RESP-AMPLIADO 16949000
                                              WS-CODMSG-ESTRUCTURA(3: 4)16949100
               MOVE WS-CT-1021N            TO WS-CT-NUMER               16949200
                                              TI-TR02-COD-RESP-AMPLIADO         
               MOVE WS-CT-001              TO TI-CF06-ORIGEN-RESPUESTA  16949300
                                              TI-TR02-ORIGEN-RESPUESTA          
               PERFORM 6100-OBTENER-MENSAJE                             16949400
                                                                        16949500
               MOVE WS-MENSAJE-TXT         TO TI-CF06-MENSAJE-RESPUESTA 16949600
               PERFORM 1340-ACTUALIZA-COMAREA                           16949700
                                                                        16949800
      *        OBTENER MENSAJE INTERNO                                  16949900
               MOVE SPACES                 TO TI-CA15-I-O-MENSAJES      16950000
               SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                      16950100
               MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT    16950200
                                              WS-CODMSG-ESTRUCTURA      16950300
                                              WS-COD-ERROR-07           16950400
               MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM            16950500
                                              WS-PROGRAM                16950600
               MOVE 'LINK'                 TO WS-VARMSG-FUN             16950700
               MOVE WS-RTN-SGTE            TO WS-VARMSG-RSO             16950800
                                                                        16950900
               PERFORM 6100-OBTENER-MENSAJE                             16951000
               MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG            16951100
                                              WS-MENSAJE-TXT-EVE        16951200
                                                                        16951300
               PERFORM 1360-GRABAR-LOG-EVENTOS                          16951400
               PERFORM 6000-FINAL                                       16951500
           END-IF                                                       16952000
           .                                                            16953000
      ************************ FIN DE 4190-RUT-LINK-GRAL                16954000
      ********************                                              16960000
       4200-BUSCAR-CAUSAL.                                              16970000
      ********************                                              16980000
                                                                        16981000
           MOVE SPACES                     TO TI-CF01-KEY05             16981100
           MOVE WS-CT-05                   TO TI-CF01-KEY05-TIP-PRM     16981200
           MOVE SPACES                     TO TI-CF01-KEY05-TIP-TRANS   16981300
           SET  TI-CA80-88-MPARAMETROS         TO TRUE                  16981400
           MOVE TI-CF01-REG-PARAMETROS         TO TI-CA80-I-REG-MPARAM  16981500
           SET  TI-CA80-I-88-TACC-CONSULTAR    TO TRUE                  16981600
           SET  TI-CA80-I-TCONS-MASIVA         TO TRUE                  16981700
                                                                        16981800
           EXEC CICS LINK PROGRAM (TI-CW03-PGM-PARAMETROS)              16981900
                          COMMAREA(TI-CA80-COMMAREA)                    16982000
                          LENGTH  (LENGTH OF TI-CA80-COMMAREA)          16982100
                          RESP (WS-RESP)                                16982200
           END-EXEC                                                     16982300
                                                                        16982400
           EVALUATE WS-RESP                                             16982500
               WHEN DFHRESP(NORMAL)                                     16982600
                   IF  TI-CA80-O-RC-NRO NOT = ZEROS                     16982700
      *                OBTENER MENSAJE PARA CCE                         16983100
                       MOVE SPACES             TO TI-CA15-I-O-MENSAJES  16983200
                                                                        16983300
                       SET  TI-CA15-I-RC-APP-CCE   TO TRUE              16983400
                       SET  TI-CF06-88-RECH        TO TRUE              16983500
                       MOVE WS-CT-05       TO TI-CF06-RESPONSE-CODE-CCE 16983600
                                              WS-TEMP-XX                16983700
                                              WS-CODMSG-ESTRUCTURA(1: 2)16983800
                                              TI-TR02-RESPONSE-CODE-CCE         
                       MOVE WS-CT-1021     TO TI-CF06-COD-RESP-AMPLIADO 16983900
                                              WS-CODMSG-ESTRUCTURA(3: 4)16984000
                       MOVE WS-CT-1021N    TO WS-CT-NUMER               16984100
                                              TI-TR02-COD-RESP-AMPLIADO         
                       MOVE WS-CT-001      TO TI-CF06-ORIGEN-RESPUESTA  16984200
                                              TI-TR02-ORIGEN-RESPUESTA          
                       PERFORM 6100-OBTENER-MENSAJE                     16984300
                                                                        16984400
                       MOVE WS-MENSAJE-TXT TO TI-CF06-MENSAJE-RESPUESTA 16984500
                                                                        16984600
      *                OBTENER MENSAJE INTERNO                          16984700
                       MOVE TI-CA80-O-RCODE    TO TI-CF06-CODMSG-ESTRUCT16984800
                                                  WS-COD-ERROR-07       16984900
                       MOVE TI-CW03-PGM-PARAMETROS                      16985000
                                               TO TI-CF06-PRGNOM        16985100
                                                  WS-PROGRAM            16985200
                       MOVE TI-CA80-O-RC-MSG   TO TI-CF06-TXTMSG        16985300
                                                  WS-MENSAJE-TXT-EVE    16985400
                                                                        16985500
                       PERFORM 1340-ACTUALIZA-COMAREA                   16985600
                       PERFORM 1360-GRABAR-LOG-EVENTOS                  16985700
                       PERFORM 6000-FINAL                               16985800
                   END-IF                                               16985900
               WHEN OTHER                                               16986000
      *            OBTENER MENSAJE PARA CCE                             16986100
                   MOVE SPACES                 TO TI-CA15-I-O-MENSAJES  16986200
                                                                        16986300
                   SET  TI-CA15-I-RC-APP-CCE   TO TRUE                  16986400
                   SET  TI-CF06-88-RECH        TO TRUE                  16986500
                   MOVE WS-CT-05           TO TI-CF06-RESPONSE-CODE-CCE 16986600
                                              WS-TEMP-XX                16986700
                                              WS-CODMSG-ESTRUCTURA(1: 2)16986800
                                              TI-TR02-RESPONSE-CODE-CCE         
                   MOVE WS-CT-1021         TO TI-CF06-COD-RESP-AMPLIADO 16986900
                                              WS-CODMSG-ESTRUCTURA(3: 4)16987000
                   MOVE WS-CT-1021N        TO WS-CT-NUMER               16987100
                                              TI-TR02-COD-RESP-AMPLIADO         
                   MOVE WS-CT-001          TO TI-CF06-ORIGEN-RESPUESTA  16987200
                                              TI-TR02-ORIGEN-RESPUESTA          
                   PERFORM 6100-OBTENER-MENSAJE                         16987300
                                                                        16987400
                   MOVE WS-MENSAJE-TXT     TO TI-CF06-MENSAJE-RESPUESTA 16987500
                   PERFORM 1340-ACTUALIZA-COMAREA                       16987600
                                                                        16987700
      *            OBTENER MENSAJE INTERNO                              16987800
                   MOVE SPACES             TO TI-CA15-I-O-MENSAJES      16987900
                   SET  TI-CA15-I-RC-APP-TTIB  TO TRUE                  16988000
                   MOVE 'TI0802'               TO TI-CF06-CODMSG-ESTRUCT16988100
                                              WS-CODMSG-ESTRUCTURA      16988200
                                              WS-COD-ERROR-07           16988300
                   MOVE WS-PROGRAM-ID          TO TI-CF06-PRGNOM        16988400
                                                  WS-PROGRAM            16988500
                   MOVE 'LINK'                 TO WS-VARMSG-FUN         16988600
                   MOVE TI-CW03-PGM-PARAMETROS TO WS-VARMSG-RSO         16988700
                                                                        16988800
                   PERFORM 6100-OBTENER-MENSAJE                         16988900
                   MOVE WS-MENSAJE-TXT         TO TI-CF06-TXTMSG        16989000
                                                  WS-MENSAJE-TXT-EVE    16989100
                                                                        16989200
                   PERFORM 1360-GRABAR-LOG-EVENTOS                      16989300
                   PERFORM 6000-FINAL                                   16989400
           END-EVALUATE                                                 16989500
                                                                        16989600
           MOVE 1 TO WS-I                                               16989700
           MOVE TI-CA80-O-REG-PARAM(WS-I)  TO TI-CF01-REG-PARAMETROS    16989800
                                                                        16989900
           PERFORM UNTIL WS-I > TI-CA80-O-NRO-REGISTROS                 16990000
             MOVE TI-CA80-O-REG-PARAM(WS-I)    TO TI-CF01-REG-PARAMETROS16990100
             IF  TI-CF01-TRAN-COD-CCE EQUAL TI-TR02-TRANS-EXTENDIDA     16990200
                 MOVE TI-CF01-KEY05-TIP-TRANS   TO TI-CF06-CAUSAL       16991000
                 MOVE TI-CA80-O-NRO-REGISTROS   TO WS-I                 17000000
                                                                        17010000
             END-IF                                                     17040000
             COMPUTE WS-I = WS-I + 1                                    17040100
                                                                        17042000
           END-PERFORM                                                  17060000
           .                                                            17221000
      ************************ FIN DE 4200-BUSCAR-CAUSAL                17230000
      **************************                                        17480000
       5000-REORDENAR-DOCUMENTO.                                        17490000
      **************************                                        17491000
      ******************************************************************17500000
      * REORDENAR LA CADENA PARA COMPLETARLA CON CEROS A LA IZQUIERDA  *17510000
      ******************************************************************17511000
                                                                        17530000
           MOVE SPACES             TO WS-DOC-ORD-TMP2                   17530200
           MOVE ZEROS              TO WS-X                              17530300
                                      WS-POS                            17530400
                                      WS-POS-INI                        17530500
                                      WS-LENGHT-CAD                     17530600
                                                                        17530700
           PERFORM VARYING WS-X FROM 1 BY 1                             17530800
                   UNTIL WS-X = WS-CTN-12                               17530900
                         OR WS-POS NOT EQUAL 0                          17531000
               IF  WS-DOC-ORD-TMP(WS-X: 1) = SPACES                     17531100
                                             OR HIGH-VALUES             17531200
                                             OR LOW-VALUES              17531300
                   MOVE WS-X           TO WS-POS                        17531400
               ELSE                                                     17531500
                   CONTINUE                                             17531600
               END-IF                                                   17531700
           END-PERFORM                                                  17531800
                                                                        17531900
           IF  WS-POS > 0                                               17532000
               COMPUTE WS-LENGHT-CAD = WS-POS - 1                       17532100
               COMPUTE WS-POS-INI = WS-CTN-12 - WS-LENGHT-CAD           17532200
               COMPUTE WS-POS-INI = WS-POS-INI + 1                      17532300
                                                                        17532400
               MOVE WS-DOC-ORD-CONST   TO WS-DOC-ORD-TMP2               17532500
               MOVE WS-DOC-ORD-TMP(1: WS-LENGHT-CAD)                    17532600
                                       TO                               17532700
                              WS-DOC-ORD-TMP2(WS-POS-INI: WS-LENGHT-CAD)17532800
                                                                        17532900
           END-IF                                                       17533000
           .                                                            17533100
      ************************ FIN DE 5000-REORDENAR-DOCUMENTO          17533200
      ************                                                      17533300
       6000-FINAL.                                                      17533400
      ************                                                      17533500
      ******************************************************************17534000
      * FIN DEL PROCESO Y ENVIA MENSAJE AL OPERADOR                    *17535000
      ******************************************************************17536000
                                                                        17537000
           IF  WS-SI-EXISTE-ERROR                                       17540000
               MOVE WS-COD-PROG          TO TI-CF06-PRGNOM              17550000
               MOVE WS-TXTMSG            TO TI-CF06-TXTMSG              17560000
               MOVE WS-CODMSG-ESTRUCTURA TO TI-CF06-CODMSG-ESTRUCT      17570000
           END-IF                                                       17580000
      *                                                                 17590000
      *    MOVE TI-TR02-I-TRAMA      TO DFHCOMMAREA                     17591000
           MOVE TI-TR02-I-TRAMA        TO TI-CA02-REG-TRANS-DATA        00160022
           MOVE TI-CA02-AREA-COMUNICACION                               00160022
                                       TO DFHCOMMAREA                   00160022
           EXEC CICS                                                    17600000
                RETURN                                                  17610000
           END-EXEC                                                     17620000
      *                                                                 17630000
           GOBACK                                                       17640000
           .                                                            17650000
      ************************ FIN DE 6000-FINAL                        17660000
      **********************                                            17661000
       6100-OBTENER-MENSAJE.                                            17662000
      **********************                                            17663000
      ******************************************************************17664000
      * MUEVE DATOS PARA LA RUTINA DE ARMADO DE MENSAJES               *17665000
      ******************************************************************17665100
                                                                        17667000
           MOVE WS-CODMSG-ESTRUCTURA       TO TI-CA15-I-RC-COD          17669200
           MOVE WS-PROGRAM-ID              TO TI-CA15-I-VAR-PROGRAMA    17669300
           MOVE WS-VARMSG-FUN              TO TI-CA15-I-VAR-FUNCION     17669400
           MOVE WS-VARMSG-RSO              TO TI-CA15-I-VAR-RECURSO     17669500
           MOVE WS-VARMSG-ARG              TO TI-CA15-I-VAR-ARGUMENTO   17669600
           MOVE WS-VARMSG-TXT              TO TI-CA15-I-VAR-TEXTO       17669700
           MOVE WS-RESP                    TO TI-CA15-I-EIBRESP         17669800
           MOVE WS-RESP2                   TO TI-CA15-I-EIBRESP2        17669900
           MOVE TI-CW03-PGM-MENSAJES       TO WS-RTN-SGTE               17670000
           MOVE TI-CA15-I-O-MENSAJES       TO WS-CCAA                   17670100
           MOVE LENGTH OF TI-CA15-I-O-MENSAJES TO WS-LGTH-CCAA          17670200
                                                                        17670300
      *    NO SE UTILIZA EL LLAMADO AL LINK-GRAL PARA NO CAER EN BUCLE  17670400
      *    SI EL PROGRAMA NO ESTA DISPONIBLE                            17670500
           EXEC  CICS  LINK  PROGRAM (WS-RTN-SGTE)                      17670600
                            COMMAREA (WS-CCAA)                          17670700
                              LENGTH (WS-LGTH-CCAA)                     17670800
                                RESP (WS-RESP)                          17670900
                               RESP2 (WS-RESP2)                         17671000
           END-EXEC                                                     17671100
                                                                        17671200
           IF  WS-RESP  NOT EQUAL  DFHRESP(NORMAL)                      17671300
               STRING 'BCTITPR2' 'RUTINA' WS-RTN-SGTE                   17671400
                      'NO DISPONIBLE EN EL CICS' DELIMITED BY SIZE INTO 17671500
                      WS-TXTMSG                                         17671600
                                                                        17671700
           ELSE                                                         17671800
               MOVE WS-CCAA                    TO TI-CA15-I-O-MENSAJES  17671900
               MOVE TI-CA15-O-RCODE            TO WS-CODMSG-ESTRUCTURA  17672000
               MOVE TI-CA15-O-RC-MSG           TO WS-TXTMSG             17672100
                                                    WS-MENSAJE-TXT      17672200
           END-IF                                                       17672300
           .                                                            17672400
      ************************ FIN DE 6100-OBTENER-MENSAJE              17672500
      ***************                                                   17672600
       9000-TERMINAR.                                                   17673000
      ***************                                                   17674000
      ******************************************************************17675000
      * TERMINAR PROGRAMA                                              *17690000
      ******************************************************************17691000
                                                                        17692000
            SET TI-CF06-88-ACEP           TO TRUE                       17710000
            MOVE WS-CT-00                 TO TI-CF06-RESPONSE-CODE-CCE  17720000
            MOVE WS-CT-0000               TO TI-CF06-COD-RESP-AMPLIADO  17721000
            MOVE WS-CT-001                TO TI-CF06-ORIGEN-RESPUESTA   17730000
            MOVE WS-CT-TRANSOK            TO TI-CF06-MENSAJE-RESPUESTA  17740000
            MOVE WS-IDC                   TO TI-CF06-IDC-BEN            17750000
            MOVE TI-TR02-APE-PAT-CLI-BENE TO TI-CF06-APE-PAT-CLI-BENE   17760000
            MOVE TI-TR02-APE-MAT-CLI-BENE TO TI-CF06-APE-MAT-CLI-BENE   17770000
            MOVE TI-TR02-NOMBRE-CLI-BENE  TO TI-CF06-NOMBRE-CLI-BENE    17780000
            MOVE SPACES                   TO TI-CF06-DIRECC-CLI-BENE    17790000
            MOVE SPACES                   TO TI-CF06-TELEF-CLI-BENE     17800000
            MOVE TI-TR02-INDI-MISMO-CLIENTE                             17810000
                                          TO TI-CF06-INDI-MISMO-CLIENTE 17820000
            MOVE WS-CT-00                 TO TI-TR02-RESPONSE-CODE-CCE  17821000
            MOVE WS-CT-0000               TO TI-TR02-COD-RESP-AMPLIADO  17830000
            MOVE WS-CT-001                TO TI-TR02-ORIGEN-RESPUESTA   17840000
            MOVE WS-CT-TRANSOK            TO TI-TR02-MENSAJE-RESPUESTA  17850000
            MOVE WS-CT-TRANSOK            TO WS-MENSAJE-TXT             17860000
            MOVE WS-CT-0000N              TO WS-CT-NUMER                17870000
            PERFORM 2000-GRABAR-MASTER-TRANSF                           17880000
            PERFORM 6000-FINAL                                          17900000
            .                                                           17901000
      ************************ FIN DE 9000-TERMINAR                     17910000
      ********************                                              17911000
       9998-OBTIENE-ABEND.                                              17920000
      ********************                                              17921000
      ******************************************************************17930000
      *OBTIENE EL CODIGO DEL ABEND GENERADO POR EL MODULO              *17940000
      ******************************************************************17941000
                                                                        17960000
            EXEC  CICS                                                  17970000
                  ASSIGN ABCODE (WS-ABCODE)                             17980000
                  ABPROGRAM (WS-ABPROGRAM)                              17990000
            END-EXEC.                                                   18000000
      ************************ FIN DE 9998-OBTIENE-ABEND                18010000
      *************************                                         18011000
       9999-MANEJO-EXCEPCIONES.                                         18020000
      *************************                                         18021000
      ******************************************************************18022000
      * ACTUALIZAR ESTADO DE LA APLICACION CAMB A ACTIVO EN BCXRAV03   *18040000
      ******************************************************************18041000
                                                                        18060000
           PERFORM  9998-OBTIENE-ABEND                                  18070000
           SET  WS-SI-EXISTE-ERROR         TO TRUE                      18080000
           MOVE 17                         TO WS-CODMSG                 18090000
           MOVE WS-ABCODE                  TO WS-TXTMSG                 18100000
           .                                                            18101000
      ************************ FIN DE 9999-MANEJO-EXCEPCIONES           18120000
