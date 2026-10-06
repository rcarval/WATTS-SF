/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Modificado por: Rodrigo López (RL)
Proyecto: Watts
Descripción: Clase para realizar la carga masiva de productos desde UI y archivo .csv
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 30-01-2026           BB                     Creación de la Clase.    
1.1 15-04-2026           RL                     Se agrega método que valida si producto existe en OrderItems 
                                                antes de cargar un nuevo csv.
***********************************************************************************/
public with sharing class SEIDOR_CargaDeProductos {

    public class ResultadoEncolado {
        @AuraEnabled public Id jobId;
        @AuraEnabled public Integer totalFilas;
        @AuraEnabled public Integer tamanoBatch;
    }

    @AuraEnabled
    public static ResultadoEncolado enqueueCreateItems(List<Map<String, Object>> rows) {

        ResultadoEncolado resultado = new ResultadoEncolado();
        resultado.tamanoBatch = 50;
        resultado.totalFilas = (rows == null) ? 0 : rows.size();


        if (rows == null || rows.isEmpty()) {
            return resultado;
        }

        List<SEIDOR_CargaDeProductos_Queueable.FilaInput> filas = new List<SEIDOR_CargaDeProductos_Queueable.FilaInput>();

        //adicion de códigos para validar
        Set<String> codigosProducto = new Set<String>();

        String idPedido = '';

        for (Map<String, Object> mapa : rows) {
            if (mapa == null) {
                continue;
            }
            SEIDOR_CargaDeProductos_Queueable.FilaInput fila = new SEIDOR_CargaDeProductos_Queueable.FilaInput();

            // Orden
            String ordenStr = valorString(mapa.get('cgcloud__Order__c'));
            if (String.isNotBlank(ordenStr)) {
                fila.idOrden = (Id) ordenStr;
                idPedido = fila.idOrden;
            }

            //Plantilla
            String plantillaStr = valorString(mapa.get('cgcloud__Order_Item_Template__c'));

            Plantillas_Permitidas__mdt cfg =
                Plantillas_Permitidas__mdt.getInstance('Plantilla_Standard');

            if (cfg == null || String.isBlank(cfg.Id_Order_Item_Template__c)) {
                throw new AuraHandledException(
                    'Error: No está configurada la plantilla permitida en Custom Metadata (Plantilla_Standard).'
                );
            }

            String plantillaPermitida = cfg.Id_Order_Item_Template__c;

            // Validación Plantilla
            if (String.isBlank(plantillaStr) || plantillaStr != plantillaPermitida) {
                throw new AuraHandledException(
                    'Error: la plantilla (cgcloud__Order_Item_Template__c) debe ser ' + plantillaPermitida +
                    '. Valor recibido: ' + (String.isBlank(plantillaStr) ? 'VACÍO' : plantillaStr)
                );
            }

            fila.idPlantillaItem = (Id) plantillaStr;

            // Producto 
            String productoStr = valorString(mapa.get('cgcloud__Product__c'));
            if (String.isNotBlank(productoStr)) {
                if (SEIDOR_CargaDeProductos_Queueable.esSalesforceId(productoStr)) {
                    fila.idProducto = (Id) productoStr;
                } else {
                    fila.codigoProducto = productoStr;
                    codigosProducto.add(productoStr);
                }
            }

            // Cantidad
            fila.cantidad = valorDecimal(mapa.get('cgcloud__Quantity__c'));
            filas.add(fila);
        }

        //VALIDACIÓN: si algún código no existe arrojar  error para el toast
        if (!Schema.SObjectType.Product2.isAccessible()) {
            throw new SecurityException('Permisos insuficientes para leer productos.');
        }

        //RL - Se agrega validación para acceder a cgcloud__Order_Item__c
        if(!Schema.SObjectType.cgcloud__Order_Item__c.isAccessible() || !Schema.SObjectType.cgcloud__Order_Item__c.isCreateable()){
            throw new SecurityException('Permisos insuficientes para leer o crear productos de pedidos.');
        }

        if (!codigosProducto.isEmpty()) {
            Set<String> codigosEncontrados = new Set<String>();
            for (Product2 p : [ //NOPMD - ApexCRUDPermission
                SELECT cgcloud__Consumer_Goods_Product_Code__c
                FROM Product2
                WHERE cgcloud__Consumer_Goods_Product_Code__c IN :codigosProducto]) {

                if (String.isNotBlank(p.cgcloud__Consumer_Goods_Product_Code__c)) {
                    codigosEncontrados.add(p.cgcloud__Consumer_Goods_Product_Code__c);
                }
            }

            Set<String> faltantes = new Set<String>();
            for (String c : codigosProducto) {
                if (!codigosEncontrados.contains(c)) {
                    faltantes.add(c); 
                }
            }

            if (!faltantes.isEmpty()) {
                throw new AuraHandledException(
                    'Error: se ha digitado un código de producto que no existe o no se encuentra. ' +
                    'Códigos no encontrados: ' + String.join(new List<String>(faltantes), ', ')
                );
            }
        }

        System.debug('codigosProducto');
        System.debug(codigosProducto);

        System.debug('cgcloud__Order__c');
        System.debug(idPedido);

        List<cgcloud__Order_Item__c> orderItemsLst = new List<cgcloud__Order_Item__c>();
        orderItemslst = [SELECT Id, Name, cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c //NOPMD - ApexCRUDViolation
                         FROM cgcloud__Order_Item__c
                         WHERE cgcloud__Order__c =: idPedido
                         AND cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c IN :codigosProducto];

        if(orderItemsLst.size() > 0){
            List<String> registros = new List<String>();

            for (cgcloud__Order_Item__c orderItem : orderItemsLst) {
                registros.add(
                    orderItem.Name + ' - ' +
                    orderItem.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c
                );
            }

            throw new AuraHandledException('Error: Algunos productos a cargar ya se encuentran registrados como Pedidos de Producto. Códigos encontrados: ' + String.join(registros, ', '));
        }

        resultado.jobId = System.enqueueJob(
            new SEIDOR_CargaDeProductos_Queueable(
                filas,
                0,
                resultado.tamanoBatch
            )
        );

        return resultado;
    }

   

    private static String valorString(Object v) {
        if (v == null) {
            return null; 
        } else {
            return String.valueOf(v).trim();
        }
    }


    private static Decimal valorDecimal(Object v) {
        if (v == null) {
            return null;
        }
        try {
            if (v instanceof Decimal){
                return (Decimal) v;
            } 
            String s = String.valueOf(v).trim().replace(',', '.');
            if (String.isBlank(s)){
                return null;
            }  
            return Decimal.valueOf(s);
        } catch (Exception e) {
            return null;
        }
    }
}