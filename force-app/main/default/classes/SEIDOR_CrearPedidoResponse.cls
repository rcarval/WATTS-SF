/**********************************************************************************
Desarrollado por: Seidor
Autor: (Brayan Baquero - BB)
Proyecto: Watts
Descripción: Clase apex de la respuesta del Cpi con datos de crear pedido.
---------------------------------------------------------------------------------
No. Fecha                Autor                     Descripción
------ ---------- ---------------------------------------------------------------
1.0 09-03-2026           BB                     Creación de la Clase.
***********************************************************************************/

public class SEIDOR_CrearPedidoResponse {
	public String PEDIDOSAP;
    public String MENSAJE;

    //mapero respuesta datos simulacion de precios response
    public String EXTERNALID;	//REQ-2026-777
	public String CUSTOMER;	//17000615
	public ClsItems[] ITEMS;
    public Double VALORNETO;
    public Double VALORBRUTO;
    public Double CREDITODISPONIBLE;
	public String ESTADO_CREDITO; //No realizado
	public class ClsItems {
		public Double ITEMID;	//10
		public String MATERIAL;	//000000000030000049
		public Double CANTIDAD;	//5
		public String UNIDAD;	//CJ
		public Double VALORNETO;	//156875
		public Double VALORIMPUESTOS;	//156875
		public String MONEDA;	//CLP
		public ClsConPrecio[] CON_PRECIO;
        public String MOTIVO_BLOQUEO;
        public String ABGRU;
	}
	public class ClsConPrecio {
		//public Double ITM_NUMBER;	//10
		//public Double COND_ST_NO;	//11
		//public Double COND_COUNT;	//1
		public String COND_TYPE;	//ZPRL
		public Double COND_VALUE;	//34861
		//public String CURRENCY_1;	//CLP
		public String COND_UNIT;	//CJ
		//public Double COND_P_UNT;	//1
		//public String CURR_ISO;	//CLP
		//public String CD_UNT_ISO;	//CJ
		//public String REFOBJTYPE;	//
		//public String REFOBJKEY;	//
		//public String REFLOGSYS;	//
		//public String APPLICATIO;	//V
		//public String CONPRICDAT;	//2026-03-04
		//public String CALCTYPCON;	//C
		//public Double CONBASEVAL;	//5
		//public Double CONEXCHRAT;	//1
		//public Double NUMCONVERT;	//1
		//public Double DENOMINATO;	//1
		//public String CONDTYPE;	//
		//public String STAT_CON;	//
		//public String SCALETYPE;	//
		//public String ACCRUALS;	//
		//public String CONINVOLST;	//
		//public String CONDORIGIN;	//A
		//public String GROUPCOND;	//
		//public String COND_UPDAT;	//
		//public Double ACCESS_SEQ;	//30
		//public Double CONDCOUNT;	//1
		//public Double ROUNDOFFDI;	//0
		public Double CONDVALUE;	//174305
		//public String CURRENCY_2;	//CLP
		//public String CURR_ISO_2;	//CLP
		//public String CONDCNTRL;	//A
		//public String CONDISACTI;	//
		//public String CONDCLASS;	//B
		//public Double FACTBASVAL;	//0
		//public String SCALEBASIN;	//
		//public Double SCALBASVAL;	//0
		//public String UNITMEASUR;	//
		//public String ISO_UNIT;	//
		//public String CURRENCKEY;	//
		//public String CURRENISO;	//
		//public String CONDINCOMP;	//
		//public String CONDCONFIG;	//
		//public String CONDCHAMAN;	//
		//public String COND_NO;	//0005876445
		//public String TAX_CODE;	//
		//public String VARCOND;	//
		//public String ACCOUNTKEY;	//
		//public String ACCOUNT_KE;	//
		//public String WT_WITHCD;	//
		//public String STRUCTCOND;	//
		//public Double FACTCONBAS;	//0
		//public Double CONDCOINHD;	//0
		//public Double ACCESS_SEQ_LONG;	//30
		//public Double COND_COUNT_LONG;	//1
		//public Double CONDCOINHD_LONG;	//0
		public String TIPO_COND;	//Precio Lista
    }

    public static SEIDOR_CrearPedidoResponse parse(String json){
        return (SEIDOR_CrearPedidoResponse) System.JSON.deserialize(json, SEIDOR_CrearPedidoResponse.class);
    }
}