/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase invocable para ejecutar creación de pedido desde Flow y guardar la respuesta.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 13-03-2026           BB                     Creación de la Clase.
***********************************************************************************/

public without sharing class SEIDOR_CrearPedido_Flow {

    public class Output {
        @InvocableVariable(label='Valor Neto')
        public Double valorNeto;

        @InvocableVariable(label='Resultado')
        public String resultado;
    }

    @InvocableMethod(
        label='Crear Pedido'
        description='Ejecuta creación de pedido desde un Flow (botón)'
    )
    public static List<Output> ejecutarDesdeFlow(List<Id> orderIds) {
	
        System.debug(orderIds);
        List<Output> resultados = new List<Output>();

        if (orderIds == null || orderIds.isEmpty()) {
            Output out = new Output();
            out.resultado = 'Error: No se recibieron OrderIds.';
            resultados.add(out);
            return resultados;
        }
		List<cgcloud__Order__c> listUpd = new List<cgcloud__Order__c>();
        
        for (Id orderId : orderIds) {
            Output out = new Output();
			cgcloud__Order__c ordenAux = SEIDOR_ConsultasSOQL.obtenerOrden(orderId);
            try {
                HttpResponse res = SEIDOR_CrearPedido.crearPedido(orderId);

                if (res != null && res.getStatusCode() == 200  ) {//&& !es200conError
                    SEIDOR_CrearPedidoResponse respuesta = SEIDOR_CrearPedidoResponse.parse(res.getBody());

                    if (respuesta != null) {
                        if(respuesta.PedidoSAP == null || respuesta.PedidoSAP == ''){
                            out.resultado = 'EXCEPCION | OrderId=' + orderId + ' | ' + respuesta.MENSAJE;
                        } else {
                            actualizarRegistrosPedidos(respuesta, orderId);
                            out.resultado = 'OK | OrderId=' + orderId + ' | Status=200';
                            out.valorNeto = respuesta.VALORNETO;
                        }
                        
                    } else {
                        out.resultado = 'EXCEPCION | OrderId=' + orderId + ' | Respuesta parseada nula';
                    }
                } else {
                    Integer sc = (res == null) ? -1 : res.getStatusCode();
                    String body = (res == null) ? 'Sin respuesta' : res.getBody();
                    out.resultado = 'EXCEPCION | OrderId=' + orderId + ' | Status=' + sc + ' | ' + body;
                }

            } catch (Exception e) {
                out.resultado = 'EXCEPCION | OrderId=' + orderId + ' | ' + e.getMessage();
                System.debug('Error: ' + e.getStackTraceString());
            }
            if(ordenAux != null && out != null){
            	ordenAux.Mensaje_SAP__c = out.resultado;    
            }
            
			listUpd.add(ordenAux);
            resultados.add(out);
        }
        if(listUpd != null && listUpd.size() > 0){
            update listUpd; //NOPMD - ApexCRUDViolation
        }
        
		 
        return resultados;
    }

    private static void actualizarRegistrosPedidos(SEIDOR_CrearPedidoResponse respuesta, Id orderId) {
        if(!Schema.SObjectType.cgcloud__Order__c.isAccessible() || !Schema.SObjectType.cgcloud__Order__c.isUpdateable()){
            System.debug('Usuario no tiene permisos para consultar o actualizar Pedidos Avanzados (cgcloud__Order__c)');
            throw new SecurityException('Usuario no tiene permisos para consultar o actualizar Pedidos Avanzados (cgcloud__Order__c)');
        }

        if(!Schema.SObjectType.cgcloud__Order_Item__c.isAccessible() || !Schema.SObjectType.cgcloud__Order_Item__c.isUpdateable()){
            System.debug('Usuario no tiene permisos para consultar o actualizar Productos de Pedidos Avanzados (cgcloud__Order_Item__c)');
            throw new SecurityException('Usuario no tiene permisos para consultar o actualizar Productos de Pedidos Avanzados (cgcloud__Order_Item__c)');
        }
        cgcloud__Order__c orden = SEIDOR_ConsultasSOQL.obtenerOrden(orderId);
        List<cgcloud__Order_Item__c> listProductos = SEIDOR_ConsultasSOQL.obtenerOrdenItems(orderId);

        List<SEIDOR_CrearPedidoResponse.ClsItems> itemServicio =
            (respuesta.ITEMS == null)
            ? new List<SEIDOR_CrearPedidoResponse.ClsItems>()
            : respuesta.ITEMS;

        orden.cgcloud__Total_Value__c = respuesta.VALORBRUTO;
        orden.cgcloud__Gross_Total_Value__c = respuesta.VALORNETO;
        orden.ID_PEDIDO_S4__c = respuesta.PedidoSAP;
        orden.Log_Crear_pedido__c = respuesta.Mensaje;
        //orden.Disponible_de_credito__c = respuesta.CREDITODISPONIBLE;
        orden.Estado_de_credito__c = respuesta.ESTADO_CREDITO;

        if (orden.codigo_watts__c == null && !String.isBlank(respuesta.PedidoSAP)) {
        	orden.codigo_watts__c = String.valueOf(Integer.ValueOF(respuesta.PedidoSAP));
        }

        if (respuesta.Mensaje == 'Pedido Creado') {
            orden.cgcloud__Phase__c = 'Closed';
        }

        update orden; //NOPMD - ApexCRUDViolation

        Account cuenta= new Account(Id=orden.cgcloud__order_Account__c, Disponible_de_Credito__c = respuesta.CREDITODISPONIBLE, Estado_Credito__c = respuesta.ESTADO_CREDITO );

        update cuenta; //NOPMD - ApexCRUDViolation

        if (listProductos != null && !listProductos.isEmpty()) {
            for (cgcloud__Order_Item__c item : listProductos) {
                for (SEIDOR_CrearPedidoResponse.ClsItems serv : itemServicio) {                    
                    if (
                        item.cgcloud__Product__r != null &&
                        item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c != null &&
                        serv.MATERIAL != null &&
                        Long.valueOf(item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c) == Long.valueOf(serv.MATERIAL)
                    ) {
                        System.debug('MPI_>'+orden.codigo_watts__c + '_' + Integer.valueOf(serv.ITEMID));
						item.codigo_watts__c = orden.codigo_watts__c + '_' + Integer.valueOf(serv.ITEMID);
                        item.cgcloud__Price__c = serv.VALORNETO;

                        if (serv.MOTIVO_BLOQUEO != null && serv.MOTIVO_BLOQUEO != '') {
                            item.Motivo_de_bloqueo__c = serv.MOTIVO_BLOQUEO;
                        }

                        List<SEIDOR_CrearPedidoResponse.ClsConPrecio> listaCondicionesPrecio =
                            (serv.CON_PRECIO == null)
                            ? new List<SEIDOR_CrearPedidoResponse.ClsConPrecio>()
                            : serv.CON_PRECIO;

                        for (SEIDOR_CrearPedidoResponse.ClsConPrecio aux : listaCondicionesPrecio) {
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

            update listProductos; //NOPMD - ApexCRUDViolation
        }
    }
}