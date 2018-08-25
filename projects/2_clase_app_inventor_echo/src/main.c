/*==================[inclusions]=============================================*/

#include "sapi.h"     // <= sAPI header
#include "main.h"


int main(void){
uint8_t dataBluetooth;

	// Inicializar la placa
	boardConfig();
	// Configura la UART 232 a 9600 Baudios.
	uartConfig(UART_232, 9600);
	// Escribe un mensaje de bienvenida
	uartWriteString(UART_232, "Hola mundo desde EDU CIAA NXP!\n\r");

	while(1) {
		// Se queda esperando que llegue informacion por bluetooth
		if (uartReadByte(UART_232, &dataBluetooth)){
			uartWriteString(UART_232, "Lo recibido por Bluetooth es: ");
			uartWriteByte  (UART_232, dataBluetooth);
			gpioToggle(LEDB);
			delay (1000);
		}
	}
	return 0 ;
}

/*==================[end of file]============================================*/
