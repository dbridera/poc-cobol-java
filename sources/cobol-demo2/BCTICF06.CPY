      ******************************************************************        
      * COPY        : BCTICF06                                         *        
      * APLICACION  : MODULO TTIB EN LINEA                             *        
      * DESCRIPCION : REGISTRO DE FILE MAESTRO TRANSACCIONAL           *        
      * ORGANIZACION: KSDS - LONGITUD DE LA LLAVE 41 BYTES             *        
      * L.R.        : 2200 BYTES                                       *        
      * NOTA        : SI SE MODIFICA EL COPY TAMBIEN DEBE APLICARSE EN *        
      *             : EL COPY BCTICFA6                                 *        
      ******************************************************************        
      *                       CONTROL DE CAMBIOS                       *        
      ******************************************************************        
      * MODIFICACION  : ADICION LOS SIGUIENTES CAMPOS:                 *00107463
      *                 - TI-CF06-TIPO-PROXY                           *00107463
      *                 - TI-CF06-VALOR-PROXY                          *00107463
      *                 - TI-CF06-IMP-COM-INTERB-EXO                   *00107463
      *                 - TI-CF06-FLG-REC-YAPE-BCP                     *00136029
      *                 - TI-CF06-TIPO-INTEROPERAB                     *00136029
      *                 - TI-CF06-FLG-EXO-COM-INTERB                   *00136029
      * FECHA         : 18-05-2023                                     *00136029
      * AFECTA A      : BCP                                            *00107463
      * MODIFICADO POR: RRH                                            *00107463
      * NRO.TICKET    : MVP00136029                                    *00136029
      ******************************************************************        
      * MODIFICACION  : ADICION DEL CAMPO TI-CF06-TERM-CICS-TETI       *00153787
      * FECHA         : 11-08-2023                                     *00153787
      * AFECTA A      : BCP                                            *00153787
      * MODIFICADO POR: RRH                                            *00153787
      * NRO.TICKET    : MVP00153787                                    *00153787
      ******************************************************************00153787
       01  TI-CF06-REG-TRANS.                                                   
           05  TI-CF06-REG-KEY-TRANS.                                           
               10  TI-CF06-COD-PROCESO             PIC  X(03).                  
                   88  TI-CF06-88-COD-PROCESO-CON  VALUE 'CON'.                 
                   88  TI-CF06-88-COD-PROCESO-TRN  VALUE 'TRN'.                 
               10  TI-CF06-TIPO-ROL                PIC  X(01).                  
                   88  TI-CF06-88-TIPO-ROL-EMISOR  VALUE 'E'.                   
                   88  TI-CF06-88-TIPO-ROL-RECEPT  VALUE 'R'.                   
               10  TI-CF06-TRACE-ADQUIRIENTE       PIC  9(06).                  
               10  TI-CF06-CANAL-CCE               PIC  9(02).                  
               10  TI-CF06-BIN-ADQUIRIENTE         PIC  X(11).                  
               10  TI-CF06-TERMINAL-ID             PIC  X(08).                  
               10  TI-CF06-FECHA-TRANS.                                         
                   15  TI-CF06-FECHA-TRANS-MM      PIC  X(02).                  
                   15  TI-CF06-FECHA-TRANS-DD      PIC  X(02).                  
               10  TI-CF06-HORA-TRANS.                                          
                   15  TI-CF06-HORA-TRANS-HH       PIC  X(02).                  
                   15  TI-CF06-HORA-TRANS-MM       PIC  X(02).                  
                   15  TI-CF06-HORA-TRANS-SS       PIC  X(02).                  
           05  TI-CF06-REG-DATOS.                                               
               10  TI-CF06-FECHA-PROCESO           PIC  9(08).                  
               10  TI-CF06-HORA-PROCESO            PIC  X(08).                  
               10  TI-CF06-CODIGO-BCO-EMI          PIC  9(03).                  
               10  TI-CF06-CANAL-BCP               PIC  X(02).                  
                   88 TI-CF06-88-CANAL-BCP-IB      VALUE 'IB'.                  
                   88 TI-CF06-88-CANAL-BCP-TN      VALUE 'TN'.                  
               10  TI-CF06-NRO-OPERACION-CNL       PIC  9(08).                  
           05  TI-CF06-ESTADO                      PIC  X(02).                  
               88  TI-CF06-88-ACEP                 VALUE '00'.                  
               88  TI-CF06-88-PEND                 VALUE '01'.                  
               88  TI-CF06-88-RECH                 VALUE '02'.                  
      *----------------------------------------------------------------*        
      *        SECCION: REENVIO                                                 
      *----------------------------------------------------------------*        
           05  TI-CF06-REENVIO                     PIC  X(02).                  
               88  TI-CF06-88-NO-REENV             VALUE '00'.                  
               88  TI-CF06-88-SI-REENV             VALUE '01'.                  
      *----------------------------------------------------------------*        
      *        SECCION: ERROR BCP TIN EN LINEA                                  
      *----------------------------------------------------------------*        
           05  TI-CF06-ERROR-BCP.                                               
               10 TI-CF06-PRGNOM                   PIC  X(08).                  
               10 TI-CF06-CODMSG-ESTRUCT.                                       
                  15 TI-CF06-CODAPP                PIC  X(02).                  
                  15 TI-CF06-CODMSG                PIC  X(04).                  
               10 TI-CF06-TXTMSG                   PIC  X(80).                  
      *----------------------------------------------------------------*        
      *        SECCION: ISO                                                     
      *----------------------------------------------------------------*        
           05  TI-CF06-NUM-LIQ-I                   PIC  X(10).                  
           05  TI-CF06-TIPO-PROCESO                PIC  X(01).                  
               88  TI-CF06-88-TIP-PROC-LINEA       VALUE 'L'.                   
               88  TI-CF06-88-TIP-PROC-BATCH       VALUE 'B'.                   
           05  TI-CF06-FECHA-PROCESO-CCE           PIC  X(10).                  
           05  TI-CF06-NRO-REFERENCIA              PIC  X(12).                  
           05  TI-CF06-AUTORIZAT-ID-RESP           PIC  X(06).                  
           05  TI-CF06-RESPONSE-CODE-CCE           PIC  X(02).                  
           05  TI-CF06-COMERCIO                    PIC  X(15).                  
           05  TI-CF06-CARD-ACEPTOR-LOCA           PIC  X(40).                  
           05  TI-CF06-COD-RESP-AMPLIADO           PIC  X(04).                  
           05  TI-CF06-ORIGEN-RESPUESTA            PIC  X(03).                  
           05  TI-CF06-MENSAJE-RESPUESTA           PIC  X(44).                  
           05  TI-CF06-ENT-BEN                     PIC  X(14).                  
           05  TI-CF06-COD-MAE-CON                 PIC  X(41).                  
      *----------------------------------------------------------------*        
      *        SECCION: TRANSACCION                                             
      *----------------------------------------------------------------*        
           05  TI-CF06-COD-APLICACION              PIC  X(03).                  
           05  TI-CF06-TIPO-SESION                 PIC  X(01).                  
           05  TI-CF06-COD-MON                     PIC  X(04).                  
               88  TI-CF06-88-COD-MON-SOL          VALUE '0001'.                
               88  TI-CF06-88-COD-MON-DOL          VALUE '1001'.                
           05  TI-CF06-CAUSAL                      PIC  X(03).                  
               88  TI-CF06-88-CAUSAL-AEC           VALUE 'AEC'.                 
               88  TI-CF06-88-CAUSAL-HAB           VALUE 'HAB'.                 
               88  TI-CF06-88-CAUSAL-PPR           VALUE 'PPR'.                 
               88  TI-CF06-88-CAUSAL-CTS           VALUE 'CTS'.                 
               88  TI-CF06-88-CAUSAL-ORP           VALUE 'ORP'.                 
               88  TI-CF06-88-CAUSAL-PCT           VALUE 'PCT'.                 
           05  TI-CF06-TIP-PAGO                    PIC  X(04).                  
               88  TI-CF06-88-TIP-PAGO-EFEC        VALUE 'EFEC'.                
               88  TI-CF06-88-TIP-PAGO-CTAD        VALUE 'CTAD'.                
               88  TI-CF06-88-TIP-PAGO-CTAR        VALUE 'CTAR'.                
               88  TI-CF06-88-TIP-PAGO-TCRE        VALUE 'TCRE'.                
           05  TI-CF06-IMPORTE                     PIC  -9(14).9999.            
           05  TI-CF06-ID-TRANS-CCE-ONLINE         PIC  X(32).                  
           05  TI-CF06-ID-TRANS-CCE-ONL-ORG        PIC  X(32).                  
           05  TI-CF06-ID-SESION.                                               
               10 TI-CF06-ID-SESION-APLICA         PIC  X(32).                  
           05  TI-CF06-AAA  REDEFINES  TI-CF06-ID-SESION.                       
               10 TI-CF06-REQUEST-ID               PIC  X(12).                  
               10 FILLER                           PIC  X(20).                  
           05  TI-CF06-CONCEPT-COBRO-TARI          PIC  X(03).                  
           05  TI-CF06-CODIGO-TARIFA               PIC  X(04).                  
           05  TI-CF06-IMPORTE-COMISION            PIC  -9(14).9999.            
           05  TI-CF06-IMP-COM-INTERB              PIC  -9(14).9999.            
           05  TI-CF06-IMP-TOT                     PIC  -9(14).9999.            
           05  TI-CF06-IMP-TIP-CAMB-USADO          PIC  -9(4).999999.           
           05  TI-CF06-IMPORTE-ORIGINAL            PIC  -9(14).9999.            
           05  TI-CF06-CRITERIO-APLICA             PIC  X(01).                  
               88  TI-CF06-88-CRIT-APLI-M          VALUE 'M'.                   
               88  TI-CF06-88-CRIT-APLI-O          VALUE 'O'.                   
               88  TI-CF06-88-CRIT-APLI-E          VALUE 'E'.                   
           05  TI-CF06-REF-TRANSFERENCIA           PIC  X(25).                  
           05  TI-CF06-INDICADOR-PAG-HAB           PIC  X(01).                  
           05  TI-CF06-MES-PAGO                    PIC  X(02).                  
           05  TI-CF06-ANIO-PAGO                   PIC  X(04).                  
           05  TI-CF06-IMPORT-SUELDO-BRUTO         PIC  9(12).                  
           05  TI-CF06-NRO-CORTE                   PIC  X(02).                  
           05  TI-CF06-ID-ALERTA                   PIC  X(02).                  
      *----------------------------------------------------------------*        
      *        SECCION: ORIGINANTE                                              
      *----------------------------------------------------------------*        
           05  TI-CF06-ENTIDAD-ORIGEN              PIC  X(08).                  
           05  TI-CF06-TIP-CTA-ORIG                PIC  X(03).                  
               88 TI-CF06-88-CTA-ORIG-004-I       VALUE '004'.                  
               88 TI-CF06-88-CTA-ORIG-005-I       VALUE '005'.                  
           05  TI-CF06-BSC-COD-FAM                 PIC  X(03).                  
           05  TI-CF06-BSC-COD-PRO                 PIC  X(03).                  
           05  TI-CF06-BSC-COD-SPR                 PIC  X(03).                  
           05  TI-CF06-NRO-CTA-ORIG                PIC  X(20).                  
           05  TI-CF06-CCI-CLI-ORIG                PIC  X(20).                  
           05  TI-CF06-TIPO-PERSONA                PIC  X(01).                  
               88  TI-CF06-TIP-PER-NAT             VALUE 'N'.                   
               88  TI-CF06-TIP-PER-JUR             VALUE 'J'.                   
           05  TI-CF06-IDC-ORI                     PIC  X(16).                  
           05  TI-CF06-TIP-DOC-CLI-ORIG            PIC  X(01).                  
           05  TI-CF06-NRO-DOC-CLI-ORIG            PIC  X(12).                  
           05  TI-CF06-TIP-CTA-MAN                 PIC  X(01).                  
           05  TI-CF06-DATOS-ORIG-VER-NOV.                                      
               10  TI-CF06-APE-PAT-CLI-ORIG        PIC  X(75).                  
               10  TI-CF06-APE-MAT-CLI-ORIG        PIC  X(40).                  
               10  TI-CF06-NOMBRE-CLI-ORIG         PIC  X(40).                  
           05  TI-CF06-DATOS-ORIG-VER-VLK   REDEFINES                           
               TI-CF06-DATOS-ORIG-VER-NOV.                                      
               10  TI-CF06-NOM-APE-ORIG            PIC  X(140).                 
               10  FILLER                          PIC  X(15).                  
           05  TI-CF06-DIRECC-CLI-ORIG             PIC  X(60).                  
           05  TI-CF06-NRO-CEL-CLI-ORIG            PIC  X(15).                  
           05  TI-CF06-DIR-MAIL-ORI                PIC  X(60).                  
      *----------------------------------------------------------------*        
      *        SECCION: BENEFICIARIO                                            
      *----------------------------------------------------------------*        
           05  TI-CF06-ENTIDAD-DESTINO             PIC  X(08).                  
           05  TI-CF06-CCI-CLI-BENEFICIA           PIC  X(20).                  
           05  TI-CF06-COD-TARJETA-CRED            PIC  X(20).                  
           05  TI-CF06-IDC-BEN                     PIC  X(16).                  
           05  TI-CF06-TIP-DOC-CLI-BENE            PIC  X(01).                  
           05  TI-CF06-NRO-DOC-CLI-BENE            PIC  X(12).                  
           05  TI-CF06-DATOS-BENEF-VER-NOV.                                     
               10  TI-CF06-APE-PAT-CLI-BENE        PIC  X(75).                  
               10  TI-CF06-APE-MAT-CLI-BENE        PIC  X(40).                  
               10  TI-CF06-NOMBRE-CLI-BENE         PIC  X(40).                  
           05  TI-CF06-DATOS-BENEF-VER-VLK  REDEFINES                           
               TI-CF06-DATOS-BENEF-VER-NOV.                                     
               10  TI-CF06-NOM-APE-BENE            PIC  X(140).                 
               10  FILLER                          PIC  X(15).                  
           05  TI-CF06-DIRECC-CLI-BENE             PIC  X(60).                  
           05  TI-CF06-TELEF-CLI-BENE              PIC  X(10).                  
           05  TI-CF06-NRO-CEL-CLI-BENE            PIC  X(15).                  
           05  TI-CF06-INDI-MISMO-CLIENTE          PIC  X(01).                  
               88  TI-CF06-88-IND-MSM-M            VALUE 'M'.                   
               88  TI-CF06-88-IND-MSM-O            VALUE 'O'.                   
           05  TI-CF06-FLG-EXO-COMISION            PIC  X(01).                  
               88  TI-CF06-88-EXO-COM-SI           VALUE 'S'.                   
               88  TI-CF06-88-EXO-COM-NO           VALUE 'N'.                   
      *----------------------------------------------------------------*        
      *        SECCION: DATOS ADICIONALES                                       
      *----------------------------------------------------------------*        
           05  TI-CF06-SUCURSAL-ORIG-OPE           PIC  X(003).                 
           05  TI-CF06-AGENCIA-ORIG-OPE            PIC  X(003).                 
           05  TI-CF06-FLG-AFECT-CNTBL             PIC  X(01).                  
               88  TI-CF06-88-AFECT-CNTBL-SI       VALUE 'S'.                   
               88  TI-CF06-88-AFECT-CNTBL-NO       VALUE 'N'.                   
           05  TI-CF06-FECHA-PROCE-CCE.                                         
               10  TI-CF06-FECHA-PROCE-CCE-MM      PIC  X(002).                 
               10  TI-CF06-FECHA-PROCE-CCE-DD      PIC  X(002).                 
           05  TI-CF06-FLG-ID-PROCESADORA          PIC  X(01).                  
               88 TI-CF06-88-ID-PROCESADORA-NOV    VALUE ' '.                   
               88 TI-CF06-88-ID-PROCESADORA-VLK    VALUE 'V'.                   
      *----------------------------------------------------------------*        
      *        SECCION: DATOS GENERALES REGISTRO                                
      *----------------------------------------------------------------*        
           05  TI-CF06-DATOS-ORIG-VER-VLK-C.                                    
               10  TI-CF06-TELEF-CLI-ORIG          PIC  X(10).                  
               10  TI-CF06-DIRECC-CLI-ORIG-C       PIC  X(10).                  
               10  FILLER                          PIC  X(80).                  
           05  TI-CF06-DATOS-BENE-VER-VLK-C.                                    
               10  TI-CF06-DIRECC-CLI-BENE-C       PIC  X(10).                  
               10  FILLER                          PIC  X(90).                  
           05  TI-CF06-DATOS-TRANSAC-VLK.                                       
               10  TI-CF06-INSTRUCTION-ID          PIC  X(035).                 
               10  TI-CF06-REF-INSTRUCTION-ID      PIC  X(035).                 
               10  TI-CF06-MONTO-LIQ               PIC  -9(14).9999.            
               10  TI-CF06-GLOSA                   PIC  X(140).                 
               10  TI-CF06-BRANCH-ID               PIC  X(035).                 
               10  TI-CF06-NUM-REINTE              PIC  9(002).                 
               10  TI-CF06-FECHA-LIQUIDA           PIC  9(008).                 
               10  TI-CF06-CONCEPT-COBRO           PIC  X(04).                  
               10  TI-CF06-REQUEST-ID-BCP          PIC  X(12).                  
      *    05  FILLER                              PIC  X(348).         00136029
           05  TI-CF06-TIPO-PROXY                  PIC  X(001).         00107463
           05  TI-CF06-VALOR-PROXY                 PIC  X(070).         00107463
           05  TI-CF06-IMP-COM-INTERB-EXO          PIC  -9(14).9999.    00107463
           05  TI-CF06-FLG-REC-YAPE-BCP            PIC  X(002).         00131509
           05  TI-CF06-TIPO-INTEROPERAB            PIC  X(001).         00131509
           05  TI-CF06-FLG-EXO-COM-INTERB          PIC  X(001).         00131509
      *    05  FILLER                              PIC  X(253).         00153787
           05  TI-CF06-TERM-CICS-TETI              PIC  X(004).         00153787
           05  FILLER                              PIC  X(249).         00153787
