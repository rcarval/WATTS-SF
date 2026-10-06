/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts

Descripción: Clase Queueable para crear cgcloud__Order_Item__c en bloques.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 30-01-2026           BB                     Creación de la Clase.  
***********************************************************************************/

public with sharing class SEIDOR_CargaDeProductos_Queueable implements Queueable {
    
    
    public class FilaInput {
        @AuraEnabled public Id idOrden;
        @AuraEnabled public Id idPlantillaItem;
        @AuraEnabled public Id idProducto;        
        @AuraEnabled public String codigoProducto; 
        @AuraEnabled public Decimal cantidad;
    }
    
    
    private List<FilaInput> filas;
    private Integer indiceInicio;
    private Integer tamanoBatch;
    
    public SEIDOR_CargaDeProductos_Queueable(
        List<FilaInput> filas,
        Integer indiceInicio,
        Integer tamanoBatch
    ) {
        this.filas = filas;
        this.indiceInicio = (indiceInicio == null) ? 0 : indiceInicio;
        this.tamanoBatch = (tamanoBatch == null || tamanoBatch <= 0) ? 50 : tamanoBatch;
    }
    
    public void execute(QueueableContext ctx) {
        if (filas == null || filas.isEmpty()) {
            return;
        }
        Integer finExclusivo = Math.min(
            indiceInicio + tamanoBatch,
            filas.size()            
        );
        
        
        List<FilaInput> batchActual = new List<FilaInput>();
        for (Integer i = indiceInicio; i < finExclusivo; i++) {
            batchActual.add(filas[i]);
        }
        
        // Recolección de productos
        
        Set<Id> idsProducto = new Set<Id>();
        Set<String> codigosProducto = new Set<String>();
        
        for (FilaInput f : batchActual) {
            if (f == null) {
              continue;  
            } 
            if (f.idProducto != null){
                idsProducto.add(f.idProducto);
            }
            if (String.isNotBlank(f.codigoProducto)) {
                codigosProducto.add(f.codigoProducto);
            }
        }
        
        
        
        // Id Products
        
        if (!Schema.SObjectType.Product2.isAccessible()) {
            throw new SecurityException('Permisos insuficientes para leer productos.');
        }
        
        
        if (!Schema.SObjectType.Product2.fields.cgcloud__Consumer_Goods_Product_Code__c.isAccessible()) {
            throw new SecurityException('Permisos insuficientes para leer el código del producto.');
        }
        
        
        
        Map<Id, Product2> productosPorId = new Map<Id, Product2>();
        if (!idsProducto.isEmpty()) {
            productosPorId = new Map<Id, Product2>([
                SELECT Id
                FROM Product2
                WHERE Id IN :idsProducto
            ]);
        }
        
        // código CG Cloud
        Map<String, Id> idProductoPorCodigo = new Map<String, Id>();
        if (!codigosProducto.isEmpty()) {
            for (Product2 p : [
                SELECT Id, cgcloud__Consumer_Goods_Product_Code__c
                FROM Product2
                WHERE cgcloud__Consumer_Goods_Product_Code__c IN :codigosProducto
            ]) {
                if (String.isNotBlank(p.cgcloud__Consumer_Goods_Product_Code__c)) {
                    idProductoPorCodigo.put(
                        p.cgcloud__Consumer_Goods_Product_Code__c,
                        p.Id
                    );
                }
            }
        }
        
        
        
        List<cgcloud__Order_Item__c> itemsAInsertar = new List<cgcloud__Order_Item__c>();
        
        for (FilaInput f : batchActual) {
            if (f == null) {
                continue; 
            }
            
                
            
            if (f.idOrden == null) {
                continue;
            }
            
            Id idProductoFinal = f.idProducto;
            
            if (idProductoFinal == null && String.isNotBlank(f.codigoProducto)) {
                idProductoFinal = idProductoPorCodigo.get(f.codigoProducto);
            }
            
            if (idProductoFinal == null) {
                continue;                
            }
            if (f.idProducto != null && !productosPorId.containsKey(f.idProducto)) {
                continue;
            }
            
            
            cgcloud__Order_Item__c item = new cgcloud__Order_Item__c();
            item.cgcloud__Order__c = f.idOrden;
            item.cgcloud__Product__c = idProductoFinal;
            
            if (f.idPlantillaItem != null) {
                item.cgcloud__Order_Item_Template__c = f.idPlantillaItem;
            }
            if (f.cantidad != null) {
                item.cgcloud__Quantity__c = f.cantidad;
            }
            
            itemsAInsertar.add(item);
        }
        
        if (!Schema.SObjectType.cgcloud__Order_Item__c.isCreateable()) {
            throw new SecurityException('Permisos insuficientes para crear Productos de Pedidos.');
        }
        
        if (!itemsAInsertar.isEmpty()) {
            Database.insert(itemsAInsertar, false); //NOPMD - ApexCRUDPermission
        }
        
        
        if (finExclusivo < filas.size()) {
            System.enqueueJob(
                new SEIDOR_CargaDeProductos_Queueable(
                    filas,
                    finExclusivo,
                    tamanoBatch
                )
            );
        }
    }
    
    
    public static Boolean esSalesforceId(String valor) {
        if (String.isBlank(valor)){ 
            return false; 
        }
        return Pattern.matches(
            '^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$',
            valor.trim()
        );
    }
    
}