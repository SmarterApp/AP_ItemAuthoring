/**
 * (c) 2005 - 2006 Sxoop Technologies Ltd. All rights reserved.
 *
 * support@sxoop.com
 */
var PXN8 = PXN8 || {};

PXN8.strings = {};

// alert when no more redo
PXN8.strings.NO_MORE_REDO     = "¡No hay más operaciones que rehacer!";

// alert when no more undo 
PXN8.strings.NO_MORE_UNDO     = "¡No hay más operaciones que deshacer!";


// alert when fully zoomed in
PXN8.strings.NO_MORE_ZOOMIN   = "¡No se puede acercar más la imagen!";

// alert when fully zoomed out
PXN8.strings.NO_MORE_ZOOMOUT       = "¡No se puede alejar más la imagen!";

// alert when using old IE (pre 6.0)
PXN8.strings.MUST_UPGRADE_IE       = "Debe actualizar a Internet Explorer 6.0 para usar PXN8";

// alert when AJAX request fails due to server error
PXN8.strings.WEB_SERVER_ERROR      = "Error del servidor web";

// alert when an image fails to load due to bad URL
PXN8.strings.IMAGE_ON_ERROR1       = "Se ha producido un error mientras se intentaba cargar";

PXN8.strings.IMAGE_ON_ERROR2       = "\nPor favor compruebe que la URL es correcta e inténtelo de nuevo";

// alert when no pxn8_config_content div has been defined
PXN8.strings.NO_CONFIG_CONTENT     = "ERROR: no hay un elemento config_content definido en su plantilla html";

PXN8.strings.CONFIG_BLUR_TOOL      = "Configurar herramienta de desenfoque (Blur)";

// appears at the bottom of the blur config tool
PXN8.strings.BLUR_PROMPT           = "Introduzca un valor entre 1 y 8 para el radio del desenfoque. Un radio mayor da como resultado una imagen más desenfocada.";

// alert when blur out of range
PXN8.strings.BLUR_RANGE            = "El radio del desenfoque debe estar entre 1 y 8";

PXN8.strings.RADIUS_LABEL          = "Radio:";
	
// alert when brightness out of range
PXN8.strings.BRIGHTNESS_RANGE      = "Introduzca un valor porcentual para el brillo";

// alert when hue out of range
PXN8.strings.HUE_RANGE             = "El valor de matiz debe ester entre 0 y 200";

// alert when saturation out of range
PXN8.strings.SATURATION_RANGE      = "Introduzca un valor porcentual para la saturación";

// appears at the top of the crop tool panel
PXN8.strings.CONFIG_CROP_TOOL      = "Configure la herramienta de corte (crop)";

PXN8.strings.CONFIG_COLOR_TOOL     = "Cambie colores";
    
// appears at the top of the lens filter tool panel
PXN8.strings.CONFIG_FILTER_TOOL    = "Configure el filtro de lente";

// appears at the bottom of the blur config tool.
PXN8.strings.FILTER_PROMPT         = "Haga clic sobre la imagen y un filtro graduado del color y la opacidad seleccionados aparecerá sobre la imagen";

// appears at the top of the interlace tool panel
PXN8.strings.CONFIG_INTERLACE_TOOL = "Configure el efecto de entrelazado";

PXN8.strings.INTERLACE_PROMPT       = "Crea una capa entrelazada sobre la imagen para que parezca una captura de TV.";

PXN8.strings.INVALID_HEX_VALUE      = "Debe introducir un valor de color hexadecimal o elegir uno de la paleta de colores";

PXN8.strings.CONFIG_LOMO_TOOL       = "Configure el efecto Lomo";

PXN8.strings.OPACITY_PROMPT         = "Una opacidad baja significa esquinas más oscuras. Una opacidad alta significa esquinas más claras.";

PXN8.strings.OPACITY_RANGE          = "La opacidad debe estar enntre 0 y 100";

PXN8.strings.WHITEN_SELECT_AREA     = "Debe seleccionar el área de la imagen que desea blanquear";

PXN8.strings.CROP_SELECT_AREA       = "Debe seleccionar el área de la imagen que quiere recortar";    

PXN8.strings.RESIZE_SELECT_AREA     = "Debe seleccionar un área para redimensionar.";

PXN8.strings.RESIZE_SELECT_LABEL    = "Redimensionar a la zona seleccionada.";

PXN8.strings.SELECT_SMALLER_AREA    = "Por favor, seleccione una zona más pequeña";

PXN8.strings.REDEYE_SELECT_AREA     = "Debe seleccionar el área que quiere arreglar";
    
PXN8.strings.REDEYE_SMALLER_AREA    = "Por favor, seleccione una zona más pequeña para arreglar(menos de 100x100)";

PXN8.strings.CONFIG_REDEYE_TOOL     = "Corregir ojos rojos";

PXN8.strings.REDEYE_PROMPT          = "Para corregir los ojos rojos, seleccione la zona afectada y haga clic sobre el botón 'Aplicar'.";
    
PXN8.strings.NUMERIC_WIDTH_HEIGHT   = "Debe especificar un valor numérico para la nueva anchura y altura";
    
PXN8.strings.LIMIT_SIZE             = "No puede redimensionar a más de ";
    
PXN8.strings.ASPECT_LABEL           = "Mantenga la proporción: ";

PXN8.strings.ASPECT_CROP_LABEL      = "Proporción: ";

PXN8.strings.CROP_FREE              = "selección libre";

PXN8.strings.CROP_SQUARE            = "(cuadrado)";

PXN8.strings.WIDTH_LABEL            = "Anchura: ";

PXN8.strings.HEIGHT_LABEL           = "Altura: ";

PXN8.strings.FLIPVT_LABEL           = "Voltear verticalmente: ";

PXN8.strings.FLIPHZ_LABEL           = "Voltear horizontalmente: ";

PXN8.strings.ANGLE_LABEL            = "Ángulo: ";
   
PXN8.strings.OPACITY_LABEL          = "Opacidad: ";
 
PXN8.strings.CONTRAST_NORMAL        = "Normal ";
 
PXN8.strings.COLOR_LABEL            = "Color: ";

PXN8.strings.SEPIA_LABEL            = "Sepia";

PXN8.strings.SATURATE_LABEL         = "Saturar:";

PXN8.strings.GRAYSCALE_LABEL        = "Escala de grises:";

PXN8.strings.ORIENTATION_LABEL      = "Orientación: ";

PXN8.strings.CONFIG_RESIZE_TOOL     = "Redimensionar imagen";
    
PXN8.strings.CONFIG_ROTATE_TOOL     = "Rotar o voltear imagen";
    
PXN8.strings.SPIRIT_LEVEL_PROMPT1   = "Por favor, haga clic sobre la mitad izquierda del horizonte recortado.";

PXN8.strings.SPIRIT_LEVEL_PROMPT2   = "OK. Ahora haga clic sobre la mitad derecha del horizonte recortado.";

PXN8.strings.CONFIG_SPIRITLVL_TOOL  = "Modo de nivelado de horizonte (Spirit-level)";
    
PXN8.strings.CONFIG_ROUNDED_TOOL    = "Configure las esquinas redondeadas";

PXN8.strings.CONFIG_BW_TOOL         = "Configure los tonos sepia o blanco y negro";

PXN8.strings.ORIENTATION_PORTRAIT   = "Retrato";

PXN8.strings.ORIENTATION_LANDSCAPE  = "Paisaje";

PXN8.strings.PROMPT_ROTATE_CHOICE   = "Por favor, especifique un ángulo de rotación o cambie la orientación";
    
PXN8.strings.BW_PROMPT              = "Pase su fotografía a blanco y negro o añada un tono sepia.";

PXN8.strings.IMAGE_UPDATING         = "Se está actualizando la imagen.\nPor favor; espere a que se complete la operación actual.";

PXN8.strings.BRIGHTNESS_LABEL        = "brillo";

PXN8.strings.SATURATION_LABEL        = "saturación";

PXN8.strings.CONTRAST_LABEL        = "contraste";

PXN8.strings.HUE_LABEL             = "matiz";

PXN8.strings.UPDATING              = "Modificando la foto. Espera por favor...";




   

