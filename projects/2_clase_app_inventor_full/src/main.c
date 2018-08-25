#include "sapi.h"        // <= Biblioteca sAPI
#include <string.h>

#define UART_PC        UART_USB
#define UART_BLUETOOTH UART_232

DEBUG_PRINT_ENABLE
CONSOLE_PRINT_ENABLE

bool_t hm10bleTest          ( int32_t uart );
void hm10blePrintATCommands ( int32_t uart );

int main( void )
{
   uint8_t data = 0;

   boardConfig();

   debugPrintConfigUart( UART_PC, 9600 ); // Inicializar UART_USB para conectar a la PC
   debugPrintlnString( "UART_PC configurada." );

   consolePrintConfigUart( UART_BLUETOOTH, 9600 ); // Inicializar UART_232 para conectar al modulo bluetooth
   debugPrintlnString( "UART_BLUETOOTH para modulo Bluetooth configurada." );

   uartWriteString( UART_PC, "Testeto si el modulo esta conectado enviando: AT\r\n" );
   if( hm10bleTest( UART_BLUETOOTH ) ){
      debugPrintlnString( "Modulo conectado correctamente." );
   }

   while( TRUE ) {
      if( uartReadByte( UART_PC, &data ) ) { // Si leo un dato de una UART lo envio a al otra (bridge)
         uartWriteByte( UART_BLUETOOTH, data );
      }
      if( uartReadByte( UART_BLUETOOTH, &data ) ) {
         if( data == 'h' ) gpioWrite( LEDB ,ON );
         if( data == 'l' ) gpioWrite( LEDB ,OFF );
         uartWriteByte( UART_PC, data );
      }
      if( !gpioRead( TEC1 ) ) {              // Si presiono TEC1 imprime la lista de comandos AT
         hm10blePrintATCommands( UART_BLUETOOTH );
      }
      if( !gpioRead( TEC3 ) ) {              // Si presiono TEC3 enciende el led de la pantalla de la app
         uartWriteString( UART_BLUETOOTH, "LED_ON\r\n" );
         delay(500);
      }
      if( !gpioRead( TEC4 ) ) {              // Si presiono TEC4 apaga el led de la pantalla de la app
         uartWriteString( UART_BLUETOOTH, "LED_OFF\r\n" );
         delay(500);
      }
   }
   return 0;
}

/*==================[definiciones de funciones externas]=====================*/

bool_t hm10bleTest( int32_t uart )
{
   uartWriteString( uart, "AT\r\n" );
   return waitForReceiveStringOrTimeoutBlocking( uart, 
                                                 "OK\r\n", strlen("OK\r\n"),
                                                 50 );
}

void hm10blePrintATCommands( int32_t uart )
{
   delay(500);
   uartWriteString( uart, "AT+HELP\r\n" );
}
/*==================[fin del archivo]========================================*/
