/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase invocable para ejecutar creación pedidos y guardar la respuesta.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 09-03-2026           BB                     Creación de la Clase.
***********************************************************************************/

public with sharing class SEIDOR_CrearPedido {

    public static HttpResponse crearPedido(Id orderId) {
        
        Activar_Log__mdt actLog = Activar_Log__mdt.getInstance('CrearPedido');

        cgcloud__Order__c orden = SEIDOR_ConsultasSOQL.obtenerOrden(orderId);
        List<cgcloud__Order_Item__c> listProductos = SEIDOR_ConsultasSOQL.obtenerOrdenItems(orderId);

        if (orden == null) {
            throw new AuraHandledException('No se encontró la orden para el Id enviado.');
        }

        if (listProductos == null || listProductos.isEmpty()) {
            throw new AuraHandledException('La orden no tiene items para enviar.');
        }

        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartObject();

        jsonGen.writeFieldName('Pedido');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('OrderId', orden.cgcloud__Order_Id__c);
        jsonGen.writeStringField('Typ_doc', orden.cgcloud__Order_Template__r.Pricing_Clase_Pedido__c);
        jsonGen.writeStringField('Customer', orden.cgcloud__Order_Account__r.cgcloud__Account_Number__c);
        jsonGen.writeStringField('Bp_entrega', orden.cgcloud__Delivery_Recipient__r.cgcloud__ExternalId__c);
        jsonGen.writeStringField('Ref_cliente', orden.Referencia_cliente__c);
        Date fechaEntrega = orden.cgcloud__Delivery_Date__c;
        String formattedFechaEntrega = DateTime.newInstance(
            fechaEntrega.year(),
            fechaEntrega.month(),
            fechaEntrega.day()
        ).format('yyyy-MM-dd');
        jsonGen.writeStringField('Fecha_entrega', formattedFechaEntrega);

        jsonGen.writeStringField('Org_venta', 'WT55');
        jsonGen.writeStringField('Canal', orden.Canal_de_distribucion__c);
        jsonGen.writeStringField('Sector', orden.Sector__c);

        // Campos no mapeados
        jsonGen.writeStringField('Centro_costo', orden.Centro__c != null ? orden.Centro__c : '');
        jsonGen.writeStringField('Estado', '');
        jsonGen.writeStringField('Motivo_bloq', '');

        // Items
        jsonGen.writeFieldName('_Items');
        jsonGen.writeStartArray();

        Integer posicion = 1;
        for (cgcloud__Order_Item__c item : listProductos) {
            jsonGen.writeStartObject();

            jsonGen.writeStringField('OrderId', orden.Id);
            jsonGen.writeStringField('ItemPosition', String.valueOf(posicion));
            jsonGen.writeStringField('Material',item.cgcloud__Product__r.cgcloud__Consumer_Goods_Product_Code__c);
            jsonGen.writeNumberField('Quantity', item.cgcloud__Quantity__c);
            jsonGen.writeStringField('Fecha_entrega', formattedFechaEntrega);
            jsonGen.writeStringField('Unit', item.cgcloud__Product__r.Unidad_de_Medida__c);
            jsonGen.writeStringField('Centro', orden.cgcloud__Order_Account__r.Centro_Suministrador__c );

            // Campos no mapeados
            jsonGen.writeStringField('Estado', '');
            jsonGen.writeStringField('Motivo_bloq', '');

            jsonGen.writeEndObject();
            posicion++;
        }

        jsonGen.writeEndArray();

        jsonGen.writeEndObject();

        jsonGen.writeEndObject();

        String bodyJson = jsonGen.getAsString();
        if(actLog.Log_Activo__c){
        	System.debug('REQUEST BODY => ' + bodyJson);
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CPI_PedidoPrecio/http/Salesforce/CreaPedido_v2');
        req.setMethod('GET');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(bodyJson);

        System.debug('REQUEST METHOD => ' + req.getMethod());
        System.debug('REQUEST ENDPOINT => ' + req.getEndpoint());

        HttpResponse res = new Http().send(req);

        System.debug('STATUS => ' + res.getStatusCode());
        if(actLog.Log_Activo__c){
        	System.debug('BODY => ' + res.getBody());
        }
        return res;
    }
}