       IDENTIFICATION DIVISION.                                                 
       PROGRAM-ID.    BCTITSCV.                                                 
       AUTHOR.        NAME AUTHOR                                               
       INSTALLATION.  BANCO DE CREDITO.                                         
       DATE-WRITTEN.  FEBRERO, 2015.                                            
      *****************************************************************         
      *                    PROPIEDAD DEL PROGRAMA                     *         
      *                                                               *         
      *   ESTE PROGRAMA Y SUS ELEMENTOS ASOCIADOS SON DE PROPIEDAD    *         
      *   DEL BANCO DE CREDITO DEL PERU Y NO PUEDE SER REPRODUCIDO,   *         
      *   DIVULGADO O UTILIZADO SIN UNA LICENCIA O AUTORIZACION       *         
      *   ESCRITA OTORGADA POR EL BANCO DE CREDITO DEL PERU.          *         
      *                                                               *         
      *****************************************************************         
      *REMARKS.                                                                 
      *****************************************************************         
      * SISTEMA   : TRANSFERENCIAS INTERBANCARIAS EN LINEA            *         
      *                                                               *         
      * MODULO    : TRANSFERENCIAS EN LINEA                           *         
      *                                                               *         
      * OBJETIVO  : OBTIENE CÓDIGO INTERBANCARIO DE CUENTAS SAVING    *         
      *             E IMPACS; OBTIENE CUENTA EN FORMATO COMERCIAL     *         
      *             EN BASE A UN CODIGO INTERBANCARIO                 *         
      *                                                               *         
      * FUNCIONES : REFORMATEA LA CUENTA EN FORMATO COMERCIAL Y GENE- *         
      *             RA LOS DIGITOS DE CHEQUEO PARA EL CODIGO INTER-   *         
      *             BANCARIO                                          *         
      * INPUT     :  - CUENTA DE IMPACS/SAVING EN FORMATO COMERCIAL   *         
      *                CODIGO INTERBANCARIO                           *         
      *              - CODIGO DEL APLICATIVO IM/ST                    *         
      *              - INDICADOR DE TRANSFORMACION                    *         
      *                                                               *         
      * OUTPUT    :  - CODIGO INTERBANCARIO X(20)                     *         
      *              - CUENTA IMPACS/SAVING EN FORMATO COMERCIAL      *         
      *                                                               *         
      *****************************************************************         
       ENVIRONMENT DIVISION.                                                    
      *                                                                         
       DATA DIVISION.                                                           
      *                                                                         
       WORKING-STORAGE SECTION.                                                 
      *-----------------------*                                                 
       01  FILLER                       PIC X(40) VALUE                         
                       'INICIO DE WORKING-STORAGE PGM BCTITSCV**'.              
       01  WS-VARIABLES.                                                        
            03  WS-TRES-NUMERO          PIC 9(03) VALUE ZEROS.                  
            03  WS-UNO-NUMERO           PIC 9(01) VALUE ZEROS.                  
            03  WS-DOS-NUMERO           PIC 9(02) VALUE ZEROS.                  
            03  FILLER REDEFINES WS-DOS-NUMERO.                                 
                05 WS-DOS-NUMERO-DEC    PIC 9(01).                              
                05 WS-DOS-NUMERO-UNI    PIC 9(01).                              
            03  WS-I1                   PIC S9(03) VALUE ZEROS COMP.            
                                                                                
       01  WS-FILL-BCO-OFI.                                                     
           03  WS-INICIAL              PIC 9(06).                               
           03  FILLER REDEFINES  WS-INICIAL.                                    
               05 WS-INICIAL-9     PIC 9(01) OCCURS 06.                         
       01  WS-FILL-TI-YRCV-DIG.                                                 
           03  WS-INICIAL2             PIC 9(12).                               
           03  FILLER REDEFINES  WS-INICIAL2.                                   
               05 WS-INICIAL-8     PIC 9(01) OCCURS 12.                         
                                                                                
       LINKAGE SECTION.                                                         
      ******************************************************************        
      * AREA DE COMUNICACIONES, PARA RECIBIR PARAMETROS DE CUENTA A    *        
      * GENERAR CODIGO INTERBANCARIO Y OBTENER EL NRO DE CUENTA        *        
      * IMPACS O SAVINGS TENIENDO EL CODIGO INTERBANCARIO              *        
      ******************************************************************        
       01  DFHCOMMAREA                 PIC  X(01).                              
       COPY BCTIYRCV.                                                           
      ********************                                                      
       PROCEDURE DIVISION USING TI-YRCV-PARAMETROS.                             
      *******************************************                               
      *                                                                         
           PERFORM 0100-INICIO                                                  
           PERFORM 0500-EVALUA-PROCESO                                          
           PERFORM 3000-FINAL                                                   
           .                                                                    
      *                                                                         
       0100-INICIO.                                                             
      *----------------------------------------------------------------*        
           EXEC  CICS                                                           
               HANDLE ABEND                                                     
                      LABEL (3000-FINAL)                                        
           END-EXEC                                                             
                                                                                
           PERFORM  0120-RECIBE-COMMAREA                                        
           .                                                                    
      *                                                                         
       0120-RECIBE-COMMAREA.                                                    
      *----------------------------------------------------------------*        
                                                                                
           IF  EIBCALEN  GREATER  0                                             
               SET  ADDRESS OF TI-YRCV-PARAMETROS                               
                                           TO ADDRESS OF DFHCOMMAREA            
           ELSE                                                                 
               MOVE  '99'    TO   TI-YRCV-COD-RETURN                            
               MOVE  'ERROR AL RECIBIR COMMAREA'  TO                            
                                  TI-YRCV-MSG-RETURN                            
           END-IF                                                               
           .                                                                    
      *-------------------------------------FIN DE 1200-RECIBE-COMMAREA*        
                                                                                
       0500-EVALUA-PROCESO.                                                     
      *-------------------*                                                     
            MOVE   TI-YRCV-COD-CTA-CCI       TO TI-YRCV-BCP-EDIT-IM             
            PERFORM 1000-VALIDA-ARGUMENTOS   THRU 1000-FINVALIDA                
            EVALUATE TRUE                                                       
                WHEN TI-YRCV-88-CCI-BCP                                         
                     PERFORM 0600-CALCULA-CTA-COMERCIAL                         
                WHEN TI-YRCV-88-BCP-CCI                                         
                     PERFORM 1500-CALCULA-CHEQUEO-INT THRU 1500-FININT          
                WHEN OTHER                                                      
                     MOVE  '99'    TO   TI-YRCV-COD-RETURN                      
                     MOVE  'COD. CONV.NO VALIDO'  TO                            
                                        TI-YRCV-MSG-RETURN                      
                GOBACK                                                          
            END-EVALUATE                                                        
            .                                                                   
       0600-CALCULA-CTA-COMERCIAL.                                              
      *-------------------------*                                               
            EVALUATE TI-YRCV-IDT-CTA                                            
      *         IMPACS BBBBBBBXXXCCCCCCCMDD                                     
                WHEN '0'                                                        
                   MOVE '004'                TO TI-YRCV-BSC-COD-FAM-RET         
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-IM              
                   MOVE TI-YRCV-NRO-CTA(2:7) TO TI-YRCV-NUM-BCP-IM              
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-IM              
                    MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-IM             
      *         SAVING BBBBBBXXXCCCCCCCCMDD                                     
                WHEN '1'                                                        
                   MOVE '005'                TO TI-YRCV-BSC-COD-FAM-RET         
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-ST              
                   MOVE TI-YRCV-NRO-CTA      TO TI-YRCV-NUM-BCP-ST              
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-ST              
                   MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-ST              
      *         CTS    BBBBBBXXXCCCCCCCCMDD                                     
                WHEN '2'                                                        
                   MOVE '009'                TO TI-YRCV-BSC-COD-FAM-RET         
                   MOVE TI-YRCV-COD-OFI      TO TI-YRCV-OFI-BCP-ST              
                   MOVE TI-YRCV-NRO-CTA      TO TI-YRCV-NUM-BCP-ST              
                   MOVE TI-YRCV-COD-MON      TO TI-YRCV-MON-BCP-ST              
                   MOVE TI-YRCV-DIG-INT1     TO TI-YRCV-DIG-BCP-ST              
            END-EVALUATE                                                        
            .                                                                   
       1000-VALIDA-ARGUMENTOS.                                                  
      *----------------------*                                                  
            MOVE  '00'        TO   TI-YRCV-COD-RETURN                           
            IF  TI-YRCV-BSC-COD-FAM-IM OR TI-YRCV-BSC-COD-FAM-ST                
                CONTINUE                                                        
            ELSE                                                                
                MOVE  '99'    TO   TI-YRCV-COD-RETURN                           
                MOVE  'COD. SIST.NO VALIDO'  TO                                 
                                   TI-YRCV-MSG-RETURN                           
                GOBACK                                                          
            END-IF.                                                             
      *                                                                         
            IF  TI-YRCV-BSC-COD-PRO IS NUMERIC                                  
                CONTINUE                                                        
            ELSE                                                                
                MOVE  '99'    TO   TI-YRCV-COD-RETURN                           
                MOVE  'ACCT.TYPE NO NUMRIC'  TO                                 
                                   TI-YRCV-MSG-RETURN                           
                GOBACK                                                          
            END-IF.                                                             
      *                                                                         
            IF  TI-YRCV-BSC-COD-FAM-IM                                          
                IF TI-YRCV-OFI-BCP-IM IS NUMERIC AND                            
                   TI-YRCV-NUM-BCP-IM IS NUMERIC AND                            
                   TI-YRCV-MON-BCP-IM IS NUMERIC AND                            
                   TI-YRCV-DIG-BCP-IM IS NUMERIC                                
                   CONTINUE                                                     
               ELSE                                                             
                   MOVE  '99'    TO   TI-YRCV-COD-RETURN                        
                   MOVE  'DATOS NO NUMERICOS '  TO                              
                                      TI-YRCV-MSG-RETURN                        
                   GOBACK                                                       
               END-IF                                                           
            ELSE                                                                
                IF TI-YRCV-OFI-BCP-ST IS NUMERIC AND                            
                   TI-YRCV-NUM-BCP-ST IS NUMERIC AND                            
                   TI-YRCV-MON-BCP-ST IS NUMERIC AND                            
                   TI-YRCV-DIG-BCP-ST IS NUMERIC                                
                   CONTINUE                                                     
               ELSE                                                             
                   MOVE  '99'    TO   TI-YRCV-COD-RETURN                        
                   MOVE  'DATOS NO NUMERICOS '  TO                              
                                      TI-YRCV-MSG-RETURN                        
                   GOBACK                                                       
               END-IF                                                           
            END-IF.                                                             
       1000-FINVALIDA.                                                          
            EXIT.                                                               
                                                                                
       1500-CALCULA-CHEQUEO-INT.                                                
      *------------------------*                                                
            MOVE '002'            TO TI-YRCV-BCO-ITE                            
            IF  TI-YRCV-BSC-COD-FAM-IM                                          
                MOVE '0'              TO TI-YRCV-PRO-ITE                        
                MOVE TI-YRCV-OFI-BCP-IM TO TI-YRCV-OFI-ITE                      
                STRING  '0'              DELIMITED BY SIZE                      
                        TI-YRCV-NUM-BCP-IM DELIMITED BY SIZE                    
                                    INTO TI-YRCV-NUM-ITE                        
                MOVE TI-YRCV-MON-BCP-IM TO TI-YRCV-MON-ITE                      
                MOVE TI-YRCV-DIG-BCP-IM TO TI-YRCV-DIG-INT                      
            ELSE                                                                
                MOVE '1'              TO TI-YRCV-PRO-ITE                        
      *         PARA CUENTAS 'CTS' SE ASIGNA '2' COMO TIPO DE PRODUCTO          
                IF  TI-YRCV-BSC-COD-FAM EQUAL '009'                             
                    MOVE '2'          TO TI-YRCV-PRO-ITE                        
                END-IF                                                          
                MOVE TI-YRCV-OFI-BCP-ST TO TI-YRCV-OFI-ITE                      
                MOVE TI-YRCV-NUM-BCP-ST TO TI-YRCV-NUM-ITE                      
                MOVE TI-YRCV-MON-BCP-ST TO TI-YRCV-MON-ITE                      
                MOVE TI-YRCV-DIG-BCP-ST TO TI-YRCV-DIG-INT                      
            END-IF                                                              
            PERFORM 2000-CALCULA-DIGCHEQ-BANOFI                                 
            MOVE ZEROS TO WS-DOS-NUMERO WS-TRES-NUMERO WS-UNO-NUMERO            
            PERFORM 3000-CALCULA-DIGCHEQ-CUENTA.                                
       1500-FININT.                                                             
            EXIT.                                                               
                                                                                
       2000-CALCULA-DIGCHEQ-BANOFI.                                             
      *---------------------------*                                             
             MOVE    TI-YRCV-OFIBAN-ITE    TO WS-INICIAL.                       
             PERFORM 2500-SUMA-NUM-IMP  VARYING WS-I1 FROM 1 BY 2               
                                                UNTIL WS-I1 > 06.               
             PERFORM 2550-SUMA-NUM-PAR  VARYING WS-I1 FROM 2 BY 2               
                                                UNTIL WS-I1 > 06.               
             COMPUTE WS-DOS-NUMERO = ( WS-TRES-NUMERO / 10 )                    
             COMPUTE WS-UNO-NUMERO = (( WS-DOS-NUMERO * 10 ) + 10 ) -           
                                      WS-TRES-NUMERO.                           
             MOVE WS-UNO-NUMERO TO TI-YRCV-DIG-ITE1.                            
                                                                                
       3000-CALCULA-DIGCHEQ-CUENTA.                                             
      *---------------------------*                                             
             MOVE    TI-YRCV-NUMERO-ITE    TO WS-INICIAL2.                      
             PERFORM 3500-SUMA-NUM-IMP2 VARYING WS-I1 FROM 1 BY 2               
                                                 UNTIL WS-I1 > 12.              
             PERFORM 3550-SUMA-NUM-PAR2 VARYING WS-I1 FROM 2 BY 2               
                                                 UNTIL WS-I1 > 12.              
             COMPUTE WS-DOS-NUMERO = ( WS-TRES-NUMERO / 10 )                    
             COMPUTE WS-UNO-NUMERO = (( WS-DOS-NUMERO * 10 ) + 10 ) -           
                                      WS-TRES-NUMERO.                           
             MOVE WS-UNO-NUMERO TO TI-YRCV-DIG-ITE2.                            
                                                                                
       2500-SUMA-NUM-IMP.                                                       
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-9 (WS-I1) * 1.                    
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +                         
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.         
       2550-SUMA-NUM-PAR.                                                       
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-9 (WS-I1) * 2.                    
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +                         
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.         
       3500-SUMA-NUM-IMP2.                                                      
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-8 (WS-I1) * 1.                    
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +                         
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.         
       3550-SUMA-NUM-PAR2.                                                      
           COMPUTE WS-DOS-NUMERO = WS-INICIAL-8 (WS-I1) * 2                     
           COMPUTE WS-TRES-NUMERO = WS-DOS-NUMERO-DEC +                         
                                    WS-DOS-NUMERO-UNI + WS-TRES-NUMERO.         
       3000-FINAL.                                                              
      *----------------------------------------------------------------*        
           EXEC CICS                                                            
                RETURN                                                          
           END-EXEC                                                             
           .                                                                    
      *                                                                         
