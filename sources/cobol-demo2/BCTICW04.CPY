      ******************************************************************        
      * COPY          : BCTICW04                                       *        
      * APLICACION    : TRANSFERENCIAS INTERBANCARIAS EN LINEA         *        
      * DESCRIPCION   : TABLA DEL SISTEMA                              *        
      * ORGANIZACION  : TABLA (BCTIAV04)                               *        
      * L.R.          : 1500   BYTES - FIJA                            *        
      ******************************************************************        
      *                                                                *        
      *              C O N T R O L   D E   C A M B I O S               *        
      ******************************************************************        
      * MODIFICACION  : VOCALINK (BASADO EN BCTICW03)                  *        
      * FECHA         : 2022                                           *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: TCS                                            *        
      * NRO.TICKET    : TA000184140                                    *        
      ******************************************************************        
      * MODIFICACION  : VOCALINK USUARIO TETI REINTENTOS               *        
      * FECHA         : JUNIO 2022                                     *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: TCS                                            *        
      * NRO.TICKET    : TA000189225                                    *        
      *----------------------------------------------------------------*        
      ******************************************************************        
      * MODIFICACION  : CAMBIO INTERVALO REINTENTOS EMISOR             *        
      * FECHA         : JULIO 2023                                     *        
      * AFECTA A      : BCP                                            *        
      * MODIFICADO POR: TCS                                            *        
      * NRO.TICKET    : MVP00146151                                    *        
      *----------------------------------------------------------------*        
       01  TI-CW04-REG-TABLA-SISTEMA.                                           
      *                                                                         
           05  TI-CW04-LONG-REG                    PIC S9(04) COMP.             
           05  TI-CW04-LONG-REG-XX  REDEFINES                                   
               TI-CW04-LONG-REG                    PIC  X(02).                  
           05  FILLER                              PIC  X(02).                  
                                                                                
      **************************************************************            
      *                                                            *            
      *              PARAMETROS DE LA INTERFAZ DE DEPOSITOS        *            
      *                                                            *            
      **************************************************************            
                                                                                
      **************************************************************            
      *                  C O N T R O L   (LR=100)                  *            
      **************************************************************            
           05  TI-CW04-CONTROL.                                                 
      *                                                                         
               10  TI-CW04-ID-TABLA-SISTEMA        PIC  X(08).                  
      *GNS-I                                                                    
      *            88  TI-CW04-88-TABLA-SISTEMA    VALUE '*TIAV03*'.            
                   88  TI-CW04-88-TABLA-SISTEMA    VALUE '*TIAV04*'.            
      *GNS-F                                                                    
      *                                                                         
               10  TI-CW04-ESTADO-SISTEMA          PIC  X(01).                  
                   88  TI-CW04-88-TTIB-ACTIVO       VALUE 'A'.                  
                   88  TI-CW04-88-TTIB-INACTIVO     VALUE 'I'.                  
                   88  TI-CW04-88-TTIB-PROCESO      VALUE 'P'.                  
      *                                                                         
               10  TI-CW04-CANAL                   PIC  X(02).                  
                   88  TI-CW04-88-TTIB             VALUE 'TI'.                  
      *                                                                         
               10  TI-CW04-INSTITUCION-APLIC       PIC  X(01).                  
                   88  TI-CW04-88-BCP              VALUE '1'.                   
                   88  TI-CW04-88-BCB              VALUE '3'.                   
      *                                                                         
               10  TI-CW04-AMBIENTE-PROCESO        PIC  X(03).                  
                   88  TI-CW04-88-DESARROLLO       VALUE 'DES'.                 
                   88  TI-CW04-88-CERTIFICACION    VALUE 'CER'.                 
                   88  TI-CW04-88-PRODUCCION       VALUE 'PRO'.                 
      *                                                                         
               10  TI-CW04-PREFIJO-APLIC           PIC  X(04).                  
                   88  TI-CW04-88-APLIC-TTIB       VALUE 'TTIB'.                
      *                                                                         
               10  TI-CW04-TBL-ALT-DISP            OCCURS 3.                    
      *      REGION CICS PRINCIPAL                                              
                   15  TI-CW04-SYSID               PIC  X(04).                  
      *      REGION CICS ALTERNA                                                
                   15  TI-CW04-SYSID-ALT           PIC  X(04).                  
      *                                                                         
               10  TI-CW04-DISP-SISTEMA            PIC  X(01).                  
                   88  TI-CW04-88-ORQ-ACTIVO       VALUE 'A'.                   
                   88  TI-CW04-88-ORQ-DESACTIVO    VALUE 'D'.                   
      *                                                                         
               10  TI-CW04-TIPO-SUBIDA             PIC  X(01).                  
                   88  TI-CW04-88-SUBIDA-NORMAL    VALUE 'N'.                   
                   88  TI-CW04-88-REARRANQUE       VALUE 'R'.                   
                   88  TI-CW04-88-INI-X-HOST       VALUE SPACE.                 
      *                                                                         
               10  TI-CW04-FLAG-NEXT-DAY           PIC  X(01).                  
                   88  TI-CW04-88-CURRENT-DAY      VALUE '0'.                   
                   88  TI-CW04-88-IN-PROCESS       VALUE '7'.                   
                   88  TI-CW04-88-NEXT-DAY         VALUE '9'.                   
                   88  TI-CW04-88-DEF-X-HOST       VALUE SPACE.                 
      *                                                                         
               10  TI-CW04-CTL-DISPONIBLE          PIC  X(54).                  
                                                                                
      *************************************************************             
      *                CONTADORES SYSPLEX (LR=80)                 *             
      *************************************************************             
           05  TI-CW04-CONTADORES-SYSPLEX.                                      
               10  TI-CW04-SYS-NRO-OPER-TRAN       PIC  X(16).                  
               10  TI-CW04-SYS-NC-NEXT-DAY         PIC  X(16).                  
               10  TI-CW04-SYS-NRO-OPER-TRAN-ND    PIC  X(16).                  
               10  TI-CW04-SYS-SESSION-ID          PIC  X(16).                  
      *GNS-I                                                                    
      *        10  TI-CW04-SYS-DISPONIBLE          PIC  X(16).                  
               10  TI-CW04-SYS-REQ-ID-TTIB         PIC  X(16).                  
      *GNS-F                                                                    
                                                                                
           05  TI-CW04-TABLA-CONT-INTF             REDEFINES                    
               TI-CW04-CONTADORES-SYSPLEX          OCCURS  05.                  
               10  TI-CW04-SYS-CONT-INTF           PIC  X(16).                  
                                                                                
      *************************************************************             
      *                      TABLAS DEL SISTEMA  (LR=40)         *              
      *************************************************************             
           05  TC-CW04-TABLAS-SISTEMA-TTIB.                                     
      *      TABLA DE PARAMETROS DEL SISTEMA                                    
               10  TC-CW04-TBL-SISTEMA             PIC  X(08).                  
               10  TC-CW04-TBL-SYS-DISPONIBLE      PIC  X(32).                  
                                                                                
      *************************************************************             
      *GNS-I                                                                    
      **              ARCHIVOS DE LA INTERFAZ (LR=160)            *             
      *               ARCHIVOS DE LA INTERFAZ (LR=200)            *             
      *GNS-F                                                                    
      *************************************************************             
           05  TI-CW04-FILES-TESO-INTF.                                         
      *      PARAMETROS GENERALES                                               
               10  TI-CW04-FILE-MAESTRO            PIC  X(08).                  
               10  TI-CW04-FILE-ACUM-DIARIO        PIC  X(08).                  
               10  TI-CW04-FILE-EVEN-LOG           PIC  X(08).                  
               10  TI-CW04-FILE-PARAMETROS         PIC  X(08).                  
               10  TI-CW04-FILE-TARIFAS            PIC  X(08).                  
               10  TI-CW04-FILE-RANGOS             PIC  X(08).                  
               10  TI-CW04-FILE-UBIGEO             PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-ALT        PIC  X(08).                  
               10  TI-CW04-FILE-ACUM-DIARIO-ALT    PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-ALT2       PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-NDAY       PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-ALT-NDAY   PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-AL2-NDAY   PIC  X(08).                  
               10  TI-CW04-FILE-MENSAJES           PIC  X(08).                  
               10  TI-CW04-FILE-REGULARIZA-EM      PIC  X(08).                  
               10  TI-CW04-FILE-REGULARIZA-RE      PIC  X(08).                  
               10  TI-CW04-FILE-EVEN-LOG-NDAY      PIC  X(08).                  
      *GNS-I                                                                    
      *        10  TI-CW04-FILES-DISPONIBLE        PIC  X(24).                  
               10  TI-CW04-FILE-REINTENTOS-RE      PIC  X(08).                  
               10  TI-CW04-FILE-REINTENTOS-EM      PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-ALT3       PIC  X(08).                  
               10  TI-CW04-FILE-MAESTRO-AL3-NDAY   PIC  X(08).                  
               10  TI-CW04-FILES-DISPONIBLE        PIC  X(32).                  
      *GNS-F                                                                    
      *                                                                         
           05  TI-CW04-FILES-INTF                  REDEFINES                    
      *GNS-I                                                                    
      *        TI-CW04-FILES-TESO-INTF             OCCURS 20.                   
               TI-CW04-FILES-TESO-INTF             OCCURS 25.                   
      *GNS-F                                                                    
               10  TI-CW04-INTF-NAME-FILE          PIC  X(08).                  
                                                                                
      *************************************************************             
      *            DATOS DE LA INTERFAZ  (LR=100)                 *             
      *************************************************************             
           05  TI-CW04-DATOS-INTF.                                              
               10  TI-CW04-DAT-INTF-NAME           PIC  X(04).                  
               10  TI-CW04-DAT-INTF-PROGRAMA       PIC  X(08).                  
               10  TI-CW04-DAT-INTF-DESCRIPCION    PIC  X(20).                  
               10  TI-CW04-DAT-INTF-LONG-MAX-I     PIC  9(05).                  
               10  TI-CW04-DAT-INTF-LONG-MIN-I     PIC  9(05).                  
               10  TI-CW04-DAT-INTF-MAX-O          PIC  9(05).                  
               10  TI-CW04-DAT-LONG-MIN-O          PIC  9(05).                  
               10  TI-CW04-TIME-CNL-MAX-SEG        PIC  9(03).                  
      *GNS-I                                                                    
      *        10  TI-CW04-DAT-DISPONIBLE          PIC  X(45).                  
               10  TI-CW04-DAT-CANT-MAX-RE         PIC  9(02).                  
               10  TI-CW04-TIME-FILE-TTIB          PIC  9(03).                  
      *TA000189225-I                                                            
      *        10  TI-CW04-DAT-DISPONIBLE          PIC  X(40).                  
               10  TI-CW04-DAT-TIME-INTERV-REI     PIC  9(03).                  
      *MVP00146151-I                                                            
               10  TI-CW04-DAT-TIME-INTERV-EMI     PIC  9(03).                  
               10  TI-CW04-DAT-DISPONIBLE          PIC  X(34).                  
      *        10  TI-CW04-DAT-DISPONIBLE          PIC  X(37).                  
      *MVP00146151-F                                                            
      *TA000189225-F                                                            
      *GNS-F                                                                    
                                                                                
      *************************************************************             
      *            PROGRAMAS CORE CENTRAL (LR=120)                *             
      *************************************************************             
           05  TI-CW04-PROGRAMAS-TTIB.                                          
               10  TI-CW04-PGM-CONSULTA            PIC  X(08).                  
               10  TI-CW04-PGM-TRANSFERENCIA       PIC  X(08).                  
               10  TI-CW04-PGM-REINTENTOS          PIC  X(08).                  
               10  TI-CW04-PGM-NOVATRONICS         PIC  X(08).                  
               10  TI-CW04-PGM-PARAMETROS          PIC  X(08).                  
               10  TI-CW04-PGM-OBT-CCI             PIC  X(08).                  
               10  TI-CW04-PGM-MENSAJES            PIC  X(08).                  
      *GNS-I                                                                    
      *        10  TI-CW04-PGM-DISPONIBLE          PIC  X(64).                  
               10  TI-CW04-PGM-CONSULTA-V02        PIC  X(08).                  
               10  TI-CW04-PGM-TRANSFERENCIA-V02   PIC  X(08).                  
               10  TI-CW04-PGM-VOCALINK            PIC  X(08).                  
               10  TI-CW04-PGM-REINTENTO-EM        PIC  X(08).                  
               10  TI-CW04-PGM-CONS-EST-ABO        PIC  X(08).                  
               10  TI-CW04-PGM-REINTENTO-RE        PIC  X(08).                  
               10  TI-CW04-PGM-DISPONIBLE          PIC  X(16).                  
      *GNS-F                                                                    
                                                                                
           05  TI-CW04-PGM-INTF                  REDEFINES                      
               TI-CW04-PROGRAMAS-TTIB            OCCURS 15.                     
               10  TI-CW04-INTF-NAME-PROG          PIC  X(08).                  
                                                                                
      *************************************************************             
      *        PROGRAMAS SERVICIOS LLAMADOS   (LR=80)             *             
      *************************************************************             
           05  TI-CW04-SERVICIOS-DPLZ.                                          
               10  TI-CW04-SRV-STDA                PIC  X(08).                  
               10  TI-CW04-SRV-VP28                PIC  X(08).                  
               10  TI-CW04-SRV-IMDS                PIC  X(08).                  
               10  TI-CW04-PGM-MQ                  PIC  X(08).                  
               10  TI-CW04-SRV-DISPONIBLE          PIC  X(48).                  
                                                                                
           05  TI-CW04-PGM-SERV                  REDEFINES                      
               TI-CW04-SERVICIOS-DPLZ       OCCURS 10.                          
               10  TI-CW04-SERV-NAME-PROG          PIC  X(08).                  
                                                                                
      *************************************************************             
      *         RUTINAS DE USO GENERAL  (LR=120)                  *             
      *************************************************************             
           05  TI-CW04-RUTINAS.                                                 
      *      RUTINA CONSULTA NEXT DAY                                           
               10  TI-CW04-RTN-NEXT-DAY            PIC  X(08).                  
      *      RUTINA VALIDACION HEADER ESTANDAR                                  
               10  TI-CW04-RTN-VALIDA-HS           PIC  X(08).                  
      *      ACCESO AL ARCHIVO DE CONEXIONES CICS                               
               10  TI-CW04-RTN-CONEXION            PIC  X(08).                  
      *      LLAMADAS A SYSTEMATIC (SEND/RECEIVE)                               
               10  TI-CW04-RTN-SEND-RECEIVE        PIC  X(08).                  
      *      LLAMADAS A RUTINA GENERAL ASIGNA USER TETI                         
               10  TI-CW04-RTN-ASIGNA-USER         PIC  X(08).                  
      *      LLAMADAS A RUTINA ASIGNA CIC CLIENTE                               
               10  TI-CW04-RTN-CONSIST             PIC  X(08).                  
      *      DISPONIBLE                                                         
               10  TI-CW04-RTN-DISPONIBLE          PIC  X(72).                  
                                                                                
      *************************************************************             
      *              SUCURSAL /  AGENCIA POR CANAL (LR=55)                      
      *                                                                         
      *************************************************************             
           05  TI-CW04-SUC-AGE.                                                 
               10  TI-CW04-SUCAGE-TABLA   OCCURS 5.                             
                   15 TI-CW04-SUCAGE-CNL               PIC  X(02).              
                   15 TI-CW04-SUCAGE-SUC               PIC  X(03).              
                   15 TI-CW04-SUCAGE-AGE               PIC  X(03).              
                   15 TI-CW04-SUCAGE-CTO-COSTO         PIC  X(03).              
                                                                                
      *************************************************************             
      *              USUARIOS APLICATIVOS POR CANAL (LR=170)                    
      *                                                                         
      *************************************************************             
           05  TI-CW04-USUARIO-APLIC.                                           
               10  TI-CW04-USUAPL-TABLA   OCCURS 5.                             
                   15 TI-CW04-USUAPL-CNL               PIC  X(02).              
                   15 TI-CW04-USUAPL-DES               PIC  X(08).              
                   15 TI-CW04-USUAPL-CER               PIC  X(08).              
                   15 TI-CW04-USUAPL-PRO               PIC  X(08).              
                   15 TI-CW04-USUAPL-INT               PIC  X(08).              
      *************************************************************             
      *                      L I B R E                                          
      *                                                                         
      *************************************************************             
           05  TI-CW04-DISPONIBLE-1                    PIC X(431).              
      *************************************************************             
