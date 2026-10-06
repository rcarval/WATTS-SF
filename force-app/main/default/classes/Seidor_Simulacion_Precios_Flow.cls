public with sharing class Seidor_Simulacion_Precios_Flow {

    @InvocableMethod(
        label='Simular Precios'
        description='Ejecuta simulación de precios desde un Flow (botón)'
    )
    public static List<String> ejecutarDesdeFlow(List<Id> orderIds) {

        List<String> resultados = new List<String>();

        if (orderIds == null || orderIds.isEmpty()) {
            resultados.add('Error: No se recibieron OrderIds.');
            return resultados;
        }

        // OJO: cada orden hace 1 callout. Máximo 100 callouts por transacción.
        for (Id orderId : orderIds) {
            try {
                HttpResponse res = Seidor_Simulacion_Precios.consultarPrecios_Orden(orderId);

                if (res != null && res.getStatusCode() == 200) {
                    resultados.add('OK | OrderId=' + orderId + ' | Status=200');
                    System.debug(res.getBody());
                    SEIDOR_SimulacionPrecioResponse respuesta = SEIDOR_SimulacionPrecioResponse.parse(res.getBody());
                    System.debug('respuesta->'+respuesta);
                    actualizarRegistros(respuesta, orderId);
                    
                } else {
                    Integer sc = (res == null) ? -1 : res.getStatusCode();
                    String body = (res == null) ? 'Sin respuesta' : res.getBody();
                    resultados.add('ERROR | OrderId=' + orderId + ' | Status=' + sc + ' | ' + body);
                }

            } catch (Exception e) {
                System.debug('Error:'+e.getStackTraceString());
                resultados.add('EXCEPCION | OrderId=' + orderId + ' | ' + e.getMessage());
            }
        }

        return resultados;
    }
    
    private static void actualizarRegistros(SEIDOR_SimulacionPrecioResponse respuesta, Id orderId){
        cgcloud__Order__c orden = SEIDOR_ConsultasSOQL.obtenerOrden(orderId);
        List<cgcloud__Order_Item__c> listProductos = SEIDOR_ConsultasSOQL.obtenerOrdenItems(orderId);
        
        List<SEIDOR_SimulacionPrecioResponse.ClsItems> itemServicio = respuesta.ITEMS;
        
        //agregar actualizacion de order cuando agreguen los valores neto y bruto
        orden.cgcloud__Total_Value__c = respuesta.VALORBRUTO;
        orden.cgcloud__Gross_Total_Value__c = respuesta.VALORNETO;
        /*if(orden.codigo_watts__c == null){
            orden.codigo_watts__c = respuesta.EXTERNALID;
        }*/
        System.debug(orden);
        update orden;
        System.debug(orden);
        
        for(cgcloud__Order_Item__c item : listProductos){
            for(SEIDOR_SimulacionPrecioResponse.ClsItems serv : itemServicio){
                System.debug('item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c->' + item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c);
                System.debug('Long.valueOf(serv.MATERIAL)->'+Long.valueOf(serv.MATERIAL));
                if(Long.valueOf(item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c) == Long.valueOf(serv.MATERIAL)){
                   // item.codigo_watts__c = respuesta.EXTERNALID + '_' + serv.ITEMID;
                    item.cgcloud__Price__c = serv.VALORNETO;
                    List<SEIDOR_SimulacionPrecioResponse.ClsConPrecio> listaCondicionesPrecio = serv.CON_PRECIO;
                    for(SEIDOR_SimulacionPrecioResponse.ClsConPrecio aux : listaCondicionesPrecio){
                        switch on orden.cgcloud__Order_Template__r.Pricing_Clase_Pedido__c {
                            when 'ZNAC' {
                                switch on aux.COND_TYPE {
                                    when 'ZPRL' {
                                        item.cgcloud_desc_Pricing_Info_1__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_1__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_1__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_1__c = aux.COND_UNIT;
                                    }
                                    when 'ZDSE' {
                                        item.cgcloud_desc_Pricing_Info_2__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_2__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_2__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_2__c = aux.COND_UNIT;
                                    }
                                    when 'ZDGD' {
                                        item.cgcloud_desc_Pricing_Info_3__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_3__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_3__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_3__c = aux.COND_UNIT;
                                    }
                                    when 'ZDPR' {
                                        item.cgcloud_desc_Pricing_Info_4__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_4__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_4__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_4__c = aux.COND_UNIT;                                        
                                    }
                                    when 'ZDIF' {
                                        item.cgcloud_desc_Pricing_Info_5__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_5__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_5__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_5__c = aux.COND_UNIT;                                        
                                    }
                                    when 'ZRSE' {
                                        item.cgcloud_desc_Pricing_Info_6__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_6__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_6__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_6__c = aux.COND_UNIT;                                        
                                    }
                                    when 'MWST' {
                                        item.cgcloud_desc_Pricing_Info_7__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_7__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_7__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_7__c = aux.COND_UNIT;                                        
                                    }
                                    when 'IABA' {
                                        item.cgcloud_desc_Pricing_Info_8__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_8__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_8__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_8__c = aux.COND_UNIT;                                        
                                    }
                                    when 'ILA' {
                                        item.cgcloud_desc_Pricing_Info_9__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_9__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_9__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_9__c = aux.COND_UNIT;                                        
                                    }                                    
                                }
                            }
                            when 'ZINT' {
                                switch on aux.COND_TYPE {
                                    when 'ZPRL' {
                                        item.cgcloud_desc_Pricing_Info_1__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_1__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_1__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_1__c = aux.COND_UNIT;
                                    }
                                    when 'ZIYL' {
                                        item.cgcloud_desc_Pricing_Info_2__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_2__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_2__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_2__c = aux.COND_UNIT;
                                    }
                                    when 'ZRSE' {
                                        item.cgcloud_desc_Pricing_Info_3__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_3__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_3__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_3__c = aux.COND_UNIT;
                                    }
                                    when 'MWST' {
                                        item.cgcloud_desc_Pricing_Info_4__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_4__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_4__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_4__c = aux.COND_UNIT;
                                    }
                                    when 'IABA' {
                                        item.cgcloud_desc_Pricing_Info_5__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_5__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_5__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_5__c = aux.COND_UNIT;
                                    }
                                    when 'ILA' {
                                        item.cgcloud_desc_Pricing_Info_6__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_6__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_6__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_6__c = aux.COND_UNIT;
                                    }                                    
                                }
                            }
                            when 'ZILQ' {
                                switch on aux.COND_TYPE {
                                    when 'ZPRL' {
                                        item.cgcloud_desc_Pricing_Info_1__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_1__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_1__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_1__c = aux.COND_UNIT;
                                    }
                                    when 'ZIYL' {
                                        item.cgcloud_desc_Pricing_Info_2__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_2__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_2__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_2__c = aux.COND_UNIT;
                                    }
                                    when 'ZRSE' {
                                        item.cgcloud_desc_Pricing_Info_3__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_3__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_3__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_3__c = aux.COND_UNIT;
                                    }
                                    when 'MWST' {
                                        item.cgcloud_desc_Pricing_Info_4__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_4__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_4__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_4__c = aux.COND_UNIT;
                                    }
                                    when 'IABA' {
                                        item.cgcloud_desc_Pricing_Info_5__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_5__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_5__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_5__c = aux.COND_UNIT;
                                    }
                                    when 'ILA' {
                                        item.cgcloud_desc_Pricing_Info_6__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_6__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_6__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_6__c = aux.COND_UNIT;
                                    }                                    
                                }
                            }
                            when 'ZVSC' {
                                switch on aux.COND_TYPE {
                                    when 'ZPRL' {
                                        item.cgcloud_desc_Pricing_Info_1__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_1__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_1__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_1__c = aux.COND_UNIT;
                                    }
                                    when 'ZDUN' {
                                        item.cgcloud_desc_Pricing_Info_2__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_2__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_2__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_2__c = aux.COND_UNIT;
                                    }
                                    when 'ZRSE' {
                                        item.cgcloud_desc_Pricing_Info_3__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_3__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_3__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_3__c = aux.COND_UNIT;
                                    }
                                    when 'MWST' {
                                        item.cgcloud_desc_Pricing_Info_4__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_4__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_4__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_4__c = aux.COND_UNIT;
                                    }
                                    when 'IABA' {
                                        item.cgcloud_desc_Pricing_Info_5__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_5__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_5__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_5__c = aux.COND_UNIT;
                                    }
                                    when 'ILA' {
                                        item.cgcloud_desc_Pricing_Info_6__c = aux.TIPO_COND;
                                        item.Importe_Pricing_Info_6__c = aux.COND_VALUE;
                                        item.cgcloud__Pricing_Info_6__c = aux.CONDVALUE;
                                        item.Unidad_Condicion_Precio_6__c = aux.COND_UNIT;
                                    }      	                              
                                }
                            }
                        }
                        
                    }
                    
                }
            }
        }
        
        if(listProductos != null){
            update listProductos;
        }
        
    }
}