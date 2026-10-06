/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase invocable que llama clases Batch AccountManagerOrgUnitBased y EffectiveAccountManagerSyncBatch
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 17-12-2025           BB                     Creación de la Clase.    
2.0 05-01-2026           BB                     Se agrega referencia de metadata para BatchSize.         
***********************************************************************************/

public class SEIDOR_EjecutaBatchCuentasInv {
    @InvocableMethod(label='Ejecutar Batches AccountManagerOrgUnitBased y EffectiveAccountManagerSyncBatch' description='Ejecutar batches AccountManagerOrgUnitBased y EffectiveAccountManagerSyncBatch')
    public static void ejecutaBatchCuenta() {
        cgcloud.AccountManagerOrgUnitBased accMgrOrgUnit= new cgcloud.AccountManagerOrgUnitBased();
        Configuracion_Batch_Size__mdt datosBatchSize = new Configuracion_Batch_Size__mdt();
        datosBatchSize = Configuracion_Batch_Size__mdt.getInstance('BatchSize');
        //En caso de no encontrar registro de metadata asume BatchSize = 5
        Integer batchSize = 5;
        if(datosBatchSize != null){
            batchSize = Integer.valueOf(datosBatchSize.Batch_Size__c);
        }
        Id accMgrOrgUnitJobId = Database.executeBatch(accMgrOrgUnit, batchSize);
          
        if(accMgrOrgUnitJobId!=null){
            System.debug('Batch 2 ejecutado correctamente. Job ID: '+accMgrOrgUnitJobId);
            SEIDOR_EjecutaBatchAccManOrgUnitQueue claseEncolable = new SEIDOR_EjecutaBatchAccManOrgUnitQueue();
            claseEncolable.idRegistroBatch = accMgrOrgUnitJobId;
            System.enqueueJob(claseEncolable,0);
        }
    }
}