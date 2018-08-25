#ejecutar con 'mdp -f tp.ms'




                                                                                               
                             ____       _                  ____       ____  
                            |  _ \ _ __(_)_   _____ _ __  |  _ \ __ _|  _ \ 
                            | | | | '__| \ \ / / _ \ '__| | |_) / _` | |_) |
                            | |_| | |  | |\ V /  __/ |    |  __/ (_| |  __/ 
                            |____/|_|  |_| \_/ \___|_|    |_|   \__,_|_|    
                                                                            
                                                                                               

-> *Para control de maquina CNC* <-

-> CESE 2018 <-
-> Protocolos de comunicación <-
-> Pablo Slavkin <-

--------------------------------------------------------------------------------

->  Diagrama de bolques de hardware <-
----------------------------------------------------

\                           ┌──────────┐
\                           │ Ethernet │
\                           └─────┬────┘
\                                 │
\              ┌─────────┐   ┌────┴───┐     ┌──────────────┐   ┌───────┐
\              │ USB/tty │───│ CM4 TI │─────│ Motor Driver │───│ Motor │
\              └─────────┘   └────┬───┘     └──────────────┘   └───────┘
\                                 │
\                            ┌────┴────┐
\                            │ ESP8266 │
\                            └─────────┘

--------------------------------------------------------------------------------

->  Diagrama de bolques implementado en firmware <-
----------------------------------------------------

\     ┌────────────────────────────────────────┐             ┌───────────┐     
\     │              FreeRTOS                  │─────────────│ QueueRcv  │     
\     └────┬─────────┬───────┬──────────────┬──┘             └─────┬─────┘     
\          │         │       │              │               ┌──────┴──────┐    
\     ┌────┴──────┐  │ ┌─────┴─────┐  ┌─────┴─────┐         │ GcodeParser │    
\     │ QueueSend │  │ │ QueueSend │  │ QueueSend │         └──────┬──────┘    
\     └─┬───────┬─┘  │ └─┬───────┬─┘  └─┬───────┬─┘           ┌────┴───┐       
\       │ Gets  │    │   │ Gets  │      │ Gets  │        ┌────│ SpiCmd │       
\       ├───────┤    │   ├───────┤      ├───────┤        │    └────────┘       
\       │ Rbuff │    │   │ Rbuff │      │ Rbuff │        │                      
\       ├───────┤    │   ├───────┤      ├───────┤        │                      
\       │  Tcp  │    │   │ UART  │      │ UART  │     ┌──┴──┐    ┌──────┐       
\       ├───────┤    │   └───┬───┘      └───┬───┘     │ SPI │────│ Busy │       
\       │ LWIP  ├────┘       │              │         └──┬──┘    └──┬───┘       
\       └──┬────┘            │              │            │          │           
\       ┌──┴──┐          ┌───┴──┐        ┌──┴───┐   ┌────┴──────┐   │           
\       │ CM4 │          │ ESP  │        │ UART │   │ powerStep │───┘           
\       │ PHY │          │ WIFI │        │  USB │   │ H─bridge  │               
\       └──┬──┘          └──┬───┘        └───┬──┘   └─────┬─────┘               
\       ┌──┴──┐          ┌──┴──┐          ┌──┴──┐     ┌───┴───┐                 
\       │ LAN │          │ LAN │          │ USB │     │ motor │                 
\       └─────┘          └─────┘          └─────┘     └───────┘                 

--------------------------------------------------------------------------------

->  Busy Flag  & SPI <-

               ┌─┐         ┌─┐ ┌─┐     ┌─┐
     Data      │ │         │ │ │ │     │ │
              ─┘ └─────────┘ └─┘ └─────┘ └─────────────────────────
               ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
     Clk       │ │ │ │ │ │ │ │ │ │ │ │ │ │
              ─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─────────────────────────
             ┌──────────────────────────────────────────────┐
     CS      │                                              │
            ─┘                                              └──────
            ─┐                                           ┌─────────
     Busy    │                                           │
             └───────────────────────────────────────────┘

-------------------------------------------------

->  Diagrama de bolques implementado en software <-
----------------------------------------------------

\                               ┌──────────┐   ┌────────┐                       
\                               │ ack_fifo │   │ driver │                       
\                               └────┬─────┘   └───┬────┘                       
\                                    │             │              
\                ┌─────────────┐  ┌──┴───┐    ┌────┴────┐  ┌─────────┐      
\                │ cat g.nc    │─>│ read │───>│ nc host │─>│ fb_fifo │      
\                └─────────────┘  └───┬──┘    │  tty    │  └────┬────┘      
\                              ┌──────┴──┐    └─────────┘       │           
\                              │   read  │                      │           
\                              │ fb_fifo │────────<─────────────┘           
\                              └─────────┘                                  

    while read -r sentence; do                               │ maxv 2000
        echo "$sentence";                                    │ acc  5000
        if read -r ack < fb_fifo; then                       │ dec  5000
          echo "$ack"  > ack_fifo;                           │ wait
        fi;                                                  │ goto 100
    done                                                     │ wait
                                                             │ goto  0
    cat g.nc > ./sender > nc 192.168.2.100 49152 > fb_fifo   │ wait
                                                             │ move 123
    cat <> ack_fifo                                          

-------------------------------------------------

->  Algunas de las funciones del driver implementadas <-
----------------------------------------------------

     init    : init regs                                                           
     run     : Sets the target speed and the motor direction                       
     step    : Puts the device in Step-clock                                       
     move    : Makes N_STEP (micro)steps in DIR direction 
     goto    : Brings motor in ABS_POS position (minimum path)                     
     gotod   : Brings motor in ABS_POS position forcing DIR direction              
     gountil : Performs a motion in DIR direction with speed SPD until SW is closed
     home    : Brings the motor in HOME position                                   
     mark    : Brings the motor in MARK position                                   
     rstpos  : Resets the ABS_POS register (sets HOME position)                    
     rst     : Device is reset to power-up conditions                              
     stop    : Stops motor with a deceleration phase                               
     hstop   : Stops motor immediately                                             
     hiz     : Puts the bridges in high impedance status after a deceleration phase
     hhiz    : Puts the bridges in high impedance status immediately               
     stat    : Returns the status register value                                   
     sp      : Set param comand ej: sp 5 1234                                      
     gp      : Get param comand ej: gp 5                                           
     pulse   : toogle pulses con direccion ej.pulse 100 1                          
     speed   : actual speed                                                        
     acc     : Acceleration                                                        
     dec     : Decceleration                                                       
     maxv    : Maximum speed                                                       
     minv    : Minimim speed                                                       
     wait    : wait                                                                
     nowait  : no wait                                                             

-------------------------------------------------








                                        _   _                 
                                /      | | (_)                
                   _ __  _ __ __ _  ___| |_ _  ___ __ _       
                  | '_ \| '__/ _` |/ __| __| |/ __/ _` |      
                  | |_) | | | (_| | (__| |_| | (_| (_| |_ _ _ 
                  | .__/|_|  \__,_|\___|\__|_|\___\__,_(_|_|_)
                  | |                                         
                  |_|                                         


-------------------------------------------------



                                                                          
                                                                          
                                               _              ___         
                                              | |            |__ \        
              _ __  _ __ ___  __ _ _   _ _ __ | |_ __ _ ___     ) |       
             | '_ \| '__/ _ \/ _` | | | | '_ \| __/ _` / __|   / /        
             | |_) | | |  __/ (_| | |_| | | | | || (_| \__ \  |_|         
             | .__/|_|  \___|\__, |\__,_|_| |_|\__\__,_|___/  (_)         
             | |              __/ |                                       
             |_|             |___/                                        
                                                                          
                                                                          

-------------------------------------------------



-> Codigos principales <-
-------------------------

-> *uart* <-




    while(1) {
       while(xSemaphoreTake(Uart_Semphr,portMAX_DELAY)!=pdTRUE)
          ;
          UARTgets ( D.Buff , BUF_SIZE );
          D.tpcb = UART_MSG;
          while(xQueueSend(Gcode_Queue,&D,portMAX_DELAY)!=pdTRUE)
             ;
          Print_Slide(&D);
    }

-------------------------------------------------

-> Codigos principales <-
-------------------------

-> *tcp* <-


      RingBufWrite(&B->RB, p->payload, p->len);
      while(!RingBufEmpty(&B->RB)) {
         Len=RingBufPeek(&B->RB,NULL);
         if(Len>=0) {
            RingBufRead(&B->RB,D.Buff,Len+1);
            D.Buff[Len]='\0';
            D.tpcb=tpcb;
            while(xQueueSend(Gcode_Queue,&D,portMAX_DELAY)!=pdTRUE)
               ;
            Print_Slide(&D);

         }

-------------------------------------------------

-> Codigos principales <-
-------------------------
-> *gcode parser* <-




    while(1) {
       struct Gcode_Queue_Struct Cmd;
       while(xQueueReceive(Gcode_Queue,&Actual_Cmd,portMAX_DELAY)!=pdTRUE)
             ;
       Cmd=Actual_Cmd;
       CmdLineProcess (Cmd.Buff,Cmd.tpcb);
    }


