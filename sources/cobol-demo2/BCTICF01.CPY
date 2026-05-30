      ******************************************************************        
      * COPY        : BCTICF01                                         *        
      * APLICACION  : TRANSFERENCIAS INTERBANCARIAS                   *         
      * MODULO      : TTIB EN LINEA                                    *        
      * DESCRIPCION : MODULO TTIB EN LINEA                             *        
      * L.R.        : 250 BYTES                                        *        
      ******************************************************************        
      *                       CONTROL DE CAMBIOS                       *        
      ******************************************************************        
      * MODIFICACION  : DEFINICION DE PARAMETROS PARA LA EXONERACION   *00107463
      *                 DE LA COMISION INTERBANCARIA                   *00107463
      * FECHA         : 18-05-2023                                     *00136029
      * AFECTA A      : BCP                                            *00107463
      * MODIFICADO POR: RRH                                            *00107463
      * NRO.TICKET    : MVP00136029                                    *00136029
      ******************************************************************        
      * MODIFICACION  : GRABAR CANAL YAPE O BANCO EN ARCHIVO MAESTRO   *00160022
      *               : VALIDA MONTO DE LA OPERAC.EN ARCH.DE PARAMETROS*        
      * FECHA         : 27 ABRIL 2023                                  *00160022
      * AFECTA A      : BCP                                            *00160022
      * MODIFICADO POR: TCS                                            *00160022
      * NRO.TICKET    : MVP00132899                                    *00160022
      *----------------------------------------------------------------*00069579
      ******************************************************************00037681
      * MODIFICACION  : COLOCAR NUEVO CAMPO PARA REPORTE BCRP          *00037681
      *               : EN KEY04 (TI-CF01-BCOS-BCR-IDE)                *00037681
      * FECHA         : 06 JUNIO 2024                                  *00037681
      * AFECTA A      : BCP                                            *00037681
      * MODIFICADO POR: RRC - BCP                                      *00037681
      * NRO.TICKET    : OCD00037681                                    *00037681
      *----------------------------------------------------------------*00037681
       01  TI-CF01-REG-PARAMETROS.                                              
           05  TI-CF01-TIP-PARMS.                                               
      *        TIPOS DE PARAMETROS                                              
               10  TI-CF01-KEY01.                                               
                   15  TI-CF01-KEY01-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY01-COD-TIP-PRM   PIC  X(002).                 
                   15  FILLER                      PIC  X(026).                 
               10  TI-CF01-DATOS-TIP-PRM.                                       
                   15  TI-CF01-TIP-PRM-DESC        PIC  X(040).                 
                   15  FILLER                      PIC  X(100).                 
           05  TI-CF01-CTABLA  REDEFINES TI-CF01-TIP-PARMS.                     
      *        CABECERA DE TABLA DE TABLAS                                      
               10  TI-CF01-KEY02.                                               
                   15  TI-CF01-KEY02-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY02-CTABL         PIC  X(003).                 
                   15  FILLER                      PIC  X(025).                 
               10  TI-CF01-DATOS-CTABLA.                                        
                   15  TI-CF01-CTBL-NOMBRE         PIC  X(030).                 
                   15  TI-CF01-CTBL-ELIMINABLE     PIC  X(001).                 
                       88  TI-CF01-CTBL-88-ELI-SI      VALUE 'S'.               
                       88  TI-CF01-CTBL-88-ELI-NO      VALUE 'N'.               
                   15  FILLER                      PIC  X(109).                 
           05  TI-CF01-DTABLA  REDEFINES TI-CF01-CTABLA.                        
      *        DETALLE O REGISTROS DE TABLAS                                    
               10  TI-CF01-KEY03.                                               
                   15  TI-CF01-KEY03-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY03-CTABL         PIC  X(003).                 
                   15  TI-CF01-KEY03-DTABL         PIC  X(016).                 
                   15  FILLER                      PIC  X(009).                 
               10  TI-CF01-DATOS-DTABLA.                                        
                   15  TI-CF01-DTBL-DESCRIPCION    PIC  X(025).                 
                   15  TI-CF01-DTBL-VALOR          PIC  X(050).                 
                   15  FILLER                      PIC  X(065).                 
      *        TABLA DE BANCOS                                                  
           05  TI-CF01-BANCOS  REDEFINES TI-CF01-DTABLA.                        
               10  TI-CF01-KEY04.                                               
                   15  TI-CF01-KEY04-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY04-BANCOS        PIC  X(003).                 
                   15  FILLER                      PIC  X(025).                 
               10  TI-CF01-DATOS-BANCOS.                                        
                   15  TI-CF01-BCOS-NOMBRE         PIC  X(030).                 
                   15  TI-CF01-BCOS-NOMBRE-CORTO   PIC  X(015).                 
                   15  TI-CF01-BCOS-SUC-PRC        PIC  X(003).                 
                   15  TI-CF01-BCOS-BCR-IDE        PIC  X(004).         00037681
                   15  FILLER                      PIC  X(088).         00037681
           05  TI-CF01-TIP-TRANSF REDEFINES TI-CF01-BANCOS.                     
      *        TABLA DE TIPOS DE TRANSFERENCIAS                                 
               10  TI-CF01-KEY05.                                               
                   15  TI-CF01-KEY05-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY05-TIP-TRANS     PIC  X(003).                 
                   15  FILLER                      PIC  X(025).                 
               10  TI-CF01-DATOS-TTRANS.                                        
                   15  TI-CF01-TRAN-COD-CCE        PIC  X(003).                 
                   15  TI-CF01-TRAN-DESCRIPCION    PIC  X(030).                 
                   15  FILLER                      PIC  X(107).                 
           05  TI-CF01-REL-BCOS-TRAN REDEFINES TI-CF01-TIP-TRANSF.              
      *        RELACION BANCOS-TIPOS DE TRANSFERENCIAS                          
               10  TI-CF01-KEY06.                                               
                   15  TI-CF01-KEY06-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY06-BANCOS        PIC  X(003).                 
                   15  TI-CF01-KEY06-TIP-TRANS     PIC  X(003).                 
                   15  FILLER                      PIC  X(022).                 
               10  TI-CF01-DATOS-BCTRAN.                                        
                   15  TI-CF01-BTRN-DESCRIPCION    PIC  X(030).                 
                   15  FILLER                      PIC  X(110).                 
           05  TI-CF01-HOM-DOCUM  REDEFINES  TI-CF01-REL-BCOS-TRAN.             
      *        HOMOLOGACION DE TIPO DE DOCUMENTO BCP - CCE                      
               10  TI-CF01-KEY07.                                               
                   15  TI-CF01-KEY07-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY07-DOC-BCP       PIC  X(001).                 
                   15  FILLER                      PIC  X(027).                 
               10  TI-CF01-DATOS-HDOCUM.                                        
                   15  TI-CF01-HDOC-DOC-CCE        PIC  X(001).                 
                   15  TI-CF01-HDOC-DESCRIPCION    PIC  X(030).                 
                   15  FILLER                      PIC  X(109).                 
           05  TI-CF01-HOM-MONEDA  REDEFINES  TI-CF01-HOM-DOCUM.                
      *        HOMOLOGACION DE MONEDA BCP - CCE                                 
               10  TI-CF01-KEY08.                                               
                   15  TI-CF01-KEY08-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY08-MON-BCP       PIC  X(004).                 
                   15  FILLER                      PIC  X(024).                 
               10  TI-CF01-DATOS-HMONED.                                        
                   15  TI-CF01-HMON-MON-CCE        PIC  X(003).                 
                   15  TI-CF01-HMON-DESCRIPCION    PIC  X(030).                 
                   15  FILLER                      PIC  X(107).                 
           05  TI-CF01-LIMITES REDEFINES TI-CF01-REL-BCOS-TRAN.                 
      *        LIMITES POR TIPO DE TRANSFERENCIA                                
               10  TI-CF01-KEY09.                                               
                   15  TI-CF01-KEY09-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY09-TIP-TRANS     PIC  X(003).                 
                   15  TI-CF01-KEY09-MON-BCP       PIC  X(004).                 
                   15  TI-CF01-KEY09-TIP-PLAZA     PIC  X(001).                 
                   15  FILLER                      PIC  X(020).                 
               10  TI-CF01-DATOS-LIMITES.                                       
                   15  TI-CF01-LMTE-DESCRIPCION    PIC  X(030).                 
                   15  TI-CF01-LMTE-MONTO-MIN      PIC  X(015).                 
                   15  TI-CF01-LMTE-MONTO-MAX      PIC  X(015).                 
                   15  FILLER                      PIC  X(080).                 
           05  TI-CF01-MENSAJES REDEFINES TI-CF01-LIMITES.                      
      *        MENSAJES                                                         
               10  TI-CF01-KEY10.                                               
                   15  TI-CF01-KEY10-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY10-APLIC         PIC  X(004).                 
                   15  TI-CF01-KEY10-COD-EXT       PIC  X(006).                 
                   15  FILLER                      PIC  X(018).                 
               10  TI-CF01-DATOS-MENSAJES.                                      
                   15  TI-CF01-MSJE-COD-INT        PIC  X(006).                 
                   15  TI-CF01-MSJE-DESCRIPCION    PIC  X(080).                 
                   15  TI-CF01-MSJE-FLAG-CSMT      PIC  X(001).                 
                       88  TI-CF01-MSJE-88-FCSMT-SI    VALUE 'S'.               
                       88  TI-CF01-MSJE-88-FCSMT-NO    VALUE 'N'.               
                   15  TI-CF01-MSJE-FLAG-LOG-EVEN  PIC  X(001).                 
                       88  TI-CF01-MSJE-88-FLOGEVE-SI  VALUE 'S'.               
                       88  TI-CF01-MSJE-88-FLOGEVE-NO  VALUE 'N'.               
                   15  FILLER                      PIC  X(052).                 
           05  TI-CONCEPTO-COBRO REDEFINES TI-CF01-MENSAJES.                    
      *        CONCEPTO DE COBRO                                                
               10  TI-CF01-KEY11.                                               
                   15  TI-CF01-KEY11-TIP-PRM       PIC  X(002).                 
                   15  TI-CF01-KEY11-CPT-COB       PIC  X(004).                 
                   15  FILLER                      PIC  X(024).                 
               10  TI-CF01-DATOS-CONCEPTO.                                      
                   15  TI-CF01-HMG-CPT-COB         PIC  X(003).                 
                   15  TI-CF01-DES-CPT-COB         PIC  X(070).                 
                   15  FILLER                      PIC  X(067).                 
           05  TI-CF01-COMI-INTERBANCARIA REDEFINES TI-CONCEPTO-COBRO.  00107463
      *        COMISION INTERBANCARIA                                   00107463
               10  TI-CF01-KEY12.                                       00107463
                   15  TI-CF01-KEY12-TIP-PRM       PIC  X(002).         00107463
                   15  TI-CF01-KEY12-CANAL         PIC  X(002).         00107463
                   15  TI-CF01-KEY12-TIP-TRANS     PIC  X(003).         00107463
                   15  TI-CF01-KEY12-MONEDA        PIC  X(004).         00107463
                   15  FILLER                      PIC  X(019).         00107463
               10  TI-CF01-DATOS-COMI-INTERB.                           00107463
                   15  TI-CF01-DES-COM-INTERB      PIC  X(030).         00107463
                   15  TI-CF01-FLG-EXO-COM-INTERB  PIC  X(001).         00107463
                   15  TI-CF01-LMTE-MAX-EXO        PIC  X(015).         00107463
                   15  FILLER                      PIC  X(094).         00107463
           05  TI-CF01-YAPE-IMPLIMYAPE REDEFINES TI-CONCEPTO-COBRO.     00132899
      *        LIMITE IMPORTE YAPE                                      00132899
               10  TI-CF01-KEY13.                                       00132899
                   15  TI-CF01-KEY13-TIP-PRM       PIC  X(002).         00132899
                   15  TI-CF01-KEY13-CANAL         PIC  X(002).         00132899
                   15  TI-CF01-KEY13-TIP-TRANS     PIC  X(003).         00132899
                   15  TI-CF01-KEY13-MONEDA        PIC  X(004).         00132899
                   15  FILLER                      PIC  X(019).         00132899
               10  TI-CF01-DATOS-YAPE-INTERB.                           00132899
                   15  TI-CF01-DES-YAPE-INTERB     PIC  X(030).         00132899
                   15  FILLER                      PIC  X(001).         00132899
                   15  TI-CF01-LMTE-MAX-IMP-YAPE   PIC  X(015).         00132899
                   15  FILLER                      PIC  X(094).         00132899
           05  TI-CF01-REGISTRO.                                                
               10  TI-CF01-REG-EST             PIC  X(001).                     
                   88  TI-CF01-REG-EST-ACTIVO      VALUE 'A'.                   
                   88  TI-CF01-REG-EST-DESACTIVO   VALUE 'D'.                   
                   88  TI-CF01-REG-EST-BLOQUEADO   VALUE 'B'.                   
               10  TI-CF01-REG-TIPO-DESACT     PIC  X(001).                     
                   88  TI-CF01-REG-DESACT-AUTOMAT  VALUE 'A'.                   
                   88  TI-CF01-REG-DESACT-MANUAL   VALUE 'M'.                   
                   88  TI-CF01-REG-DESACT-X-BATCH  VALUE 'B'.                   
               10  TI-CF01-REG-COD-DESACT      PIC  X(002).                     
                   88  TI-CF01-REG-DESACT-X-DIA    VALUE '01'.                  
                   88  TI-CF01-REG-DESACT-TEMPORAL VALUE '02'.                  
                   88  TI-CF01-REG-DESACT-PERM     VALUE '03'.                  
           05  TI-CF01-CREACION.                                                
               10  TI-CF01-CRE-FECHA           PIC  X(008).                     
               10  TI-CF01-CRE-HORA            PIC  X(006).                     
               10  TI-CF01-CRE-MATRICULA       PIC  X(008).                     
           05  TI-CF01-ULT-ACTUALIZACION.                                       
               10  TI-CF01-ACT-FECHA           PIC  X(008).                     
               10  TI-CF01-ACT-HORA            PIC  X(006).                     
               10  TI-CF01-ACT-MATRICULA       PIC  X(008).                     
           05  TI-CF01-DISPONIBLE.                                              
               10  TI-CF01-DISP                PIC  X(032).                     
