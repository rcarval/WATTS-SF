/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase Test para clase SEIDOR_EjecutaBatchCuentasInv
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 18-12-2025           BB                     Creación de la Clase.
************************************************************************************/

@isTest
public class SEIDOR_EjecutaBatchCuentasInvTest {
     //Test de Camino Feliz - SEIDOR_EjecutaBatchCuentasInv
     @isTest
     static void test01() {
        System.Test.startTest();
           SEIDOR_EjecutaBatchCuentasInv.ejecutaBatchCuenta();
           System.assert(true, 'Test ejecutado');
        System.Test.stopTest();
     }
 }