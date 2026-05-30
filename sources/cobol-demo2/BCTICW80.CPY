      ******************************************************************00010000
      * COPY        : BCTICW80                                         *00020000
      * APLICACION  : TRANSFERENCIAS INTERBANCARIAS                    *00030000
      * DESCRIPCION : MENSAJES QUE USAN LOS PROGRAMAS DE MODULO TI8A   *00040000
      ******************************************************************00050000
      *----------------------------------------------------------------*00060000
      *    MENSAJES DE RESPUESTA DE LA RUTINA                          *00070000
      *----------------------------------------------------------------*00080000
       01  TI-CW80-MENSAJES.                                            00090000
           05  F           PIC  X(87)      VALUE 'TI0401-BCTITP80 CAMPO 00090100
      -    'ID DEL AREA DE COMUNICACION INCORRECTO, DEBE SER *TICA80*   00090200
      -    '     '.                                                     00090400
           05  F           PIC  X(87)      VALUE 'TI0402-BCTITP80 CAMPO 00090500
      -    'TIPO DE ACCION NO ES VALIDO.                                00090600
      -    '     '.                                                     00090700
           05  F           PIC  X(87)      VALUE 'TI0403-BCTITP80 REGIST00090800
      -    'RO YA EXISTE EN ARCHIVO BCTIPRM1.                           00090900
      -    '     '.                                                     00091000
           05  F           PIC  X(87)      VALUE 'TI0413-BCTITP80 REGIST00091100
      -    'RO NO ENCONTRADO EN ARCHIVO DE PARAMETROS.                  00091200
      -    '     '.                                                     00091300
           05  F           PIC  X(87)      VALUE 'TI0801-BCTITP80 ERROR 00091400
      -    'AL LEER ARCHIVO BCTIPRM1.                                   00091500
      -    '     '.                                                     00092000
           05  F           PIC  X(87)      VALUE 'TI0802-BCTITP80 ERROR 00100000
      -    'AL ESCRIBIR EN ARCHIVO BCTIPRM1.                            00110000
      -    '     '.                                                     00111000
           05  F           PIC  X(87)      VALUE 'TI0803-BCTITP80 ERROR 00120000
      -    'AL REESCRIBIR REGISTRO EN ARCHIVO BCTIPRM1.                 00130000
      -    '     '.                                                     00131000
           05  F           PIC  X(87)      VALUE 'TI0804-BCTITP80 ERROR 00140000
      -    'AL ELIMINAR REGISTRO EN ARCHIVO BCTIPRM1.                   00150000
      -    '     '.                                                     00160000
           05  F           PIC  X(87)      VALUE 'TI0805-BCTITP80 ERROR 00180000
      -    'EN STARTBR EN EL ARCHIVO BCTIPRM1.                          00190000
      -    '     '.                                                     00191000
           05  F           PIC  X(87)      VALUE 'TI0806-BCTITP80 ERROR 00200000
      -    'EN LEER SIGUIENTE REGISTRO DEL ARCHIVO BCTIPRM1.            00210000
      -    '     '.                                                     00211000
           05  F           PIC  X(87)      VALUE 'TI0807-BCTITP80 ERROR 00220000
      -    'EN ENDBR EN EL ARCHIVO BCTIPRM1.                            00221000
      -    '     '.                                                     00221100
       01  FILLER          REDEFINES       TI-CW80-MENSAJES.            00800000
           05  TI-CW80-MSJE-OCC    OCCURS 011 TIMES    INDEXED BY WS-N. 00810000
               10  TI-CW80-MSJE-RPTA.                                   00820000
                   15  TI-CW80-MSJ-COD-RET.                             00821000
                       20  TI-CW80-MSJ-APLIC-RGEN  PIC  X(02).          00830000
                       20  TI-CW80-MSJ-COD-SEC     PIC  9(04).          00840000
                   15  TI-CW80-MSJ-GUION           PIC  X(01).          00850000
                   15  TI-CW80-MSJ-TXT             PIC  X(80).          00860000
       01  FILLER.                                                      00870000
           05  TI-CW80-CD-RET-FND                  PIC  X(01).          00880000
               88  TI-CW80-CD-RET-FOUND            VALUE 'S'.           00890000
               88  TI-CW80-CD-RET-NOT-FOUND        VALUE 'N'.           00900000
                                                                        00910000
      *----------------------------------------------------------------*00911000
      *    MENSAJES DE RESPUESTA VARIABLES DEL MOTOR CENTRAL           *00912000
      *----------------------------------------------------------------*00913000
       01  TI-CW80-MENSAJES-VARIABLES.                                  00914000
                                                                        00915000
           05  TI-CW80-ERROR-RPTA.                                      00916000
               10  TI-CW80-ERROR-RPTA-COD.                              00917000
                   15  TI-CW80-ERROR-RPTA-C-APL    PIC  X(02).          00918000
                   15  TI-CW80-ERROR-RPTA-C-NRO    PIC  9(04).          00919000
               10  TI-CW80-ERROR-RPTA-GUION        PIC  X(01).          00919100
               10  TI-CW80-ERROR-RPTA-TXT          PIC  X(80).          00919200
      *----------------------------------------------------------------*00919300
      *        PARA REPORTAR ERRORES EN PROGRAMA - TABLA DE MENSAJES   *00919400
      *----------------------------------------------------------------*00919500
           05  TI-CW80-MSJ-Z-0499.                                      00919700
               10  TI-CW80-MSJ-Z-TXT1          PIC  X(31)               00919800
                   VALUE 'TI0499-BCTITP80 CODIGO RETORNO:'.             00919900
               10  TI-CW80-MSJ-Z-CD-ERROR      PIC  X(06).              00920000
               10  TI-CW80-MSJ-Z-TXT2          PIC  X(50)               00930000
                   VALUE ' NO EXISTE EN TABLA DE MANEJO DE MENSAJES BCTI00940000
      -        'CW80'.                                                  00950000
                                                                        00960000
