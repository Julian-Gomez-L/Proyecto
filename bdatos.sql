-- ============================================================
--  BASE DE DATOS: BaseCamas El Dormilón - ERP
--  Generado para el sistema de gestión de pedidos y producción
-- ============================================================

CREATE DATABASE IF NOT EXISTS basecamas_erp
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE basecamas_erp;

-- ============================================================
-- TABLA: t_roles
-- Almacena los roles disponibles en el sistema
-- Roles: Asesor Comercial, Confirmación, Fabricación, Administración
-- ============================================================
CREATE TABLE IF NOT EXISTS t_roles (
    id_rol          INT(11)         AUTO_INCREMENT  NOT NULL,
    nombre_rol      VARCHAR(50)                     NOT NULL,
    descripcion     VARCHAR(200),
    esta_activo     TINYINT(1)                      NOT NULL DEFAULT 1,
    CONSTRAINT pk_rol           PRIMARY KEY (id_rol),
    CONSTRAINT uq_nombre_rol    UNIQUE (nombre_rol)
) ENGINE=InnoDB;

INSERT INTO t_roles VALUES
    (NULL, 'Administración',    'Acceso total al sistema',                          1),
    (NULL, 'Asesor Comercial',  'Creación y seguimiento de pedidos propios',        1),
    (NULL, 'Confirmación',      'Revisión y confirmación de pedidos',               1),
    (NULL, 'Fabricación',       'Gestión de producción y estados de tapicería',     1);


-- ============================================================
-- TABLA: t_usuarios
-- Todos los usuarios del sistema (asesores, tapiceros, admin, etc.)
-- Nota: t_tapicero se elimina; los tapiceros son usuarios con rol Fabricación
-- ============================================================
CREATE TABLE IF NOT EXISTS t_usuarios (
    id_usuario          INT(11)         AUTO_INCREMENT  NOT NULL,
    tipo_documento      VARCHAR(30)                     NOT NULL,
    numero_documento    VARCHAR(20)                     NOT NULL,
    nombre              VARCHAR(100)                    NOT NULL,
    email               VARCHAR(200)                    NOT NULL,
    password            VARCHAR(200)                    NOT NULL,
    telefono            VARCHAR(20),
    foto_perfil         VARCHAR(255),
    fecha_creacion      DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    esta_activo         TINYINT(1)                      NOT NULL DEFAULT 1,
    id_rol              INT(11)                         NOT NULL,
    CONSTRAINT pk_usuario           PRIMARY KEY (id_usuario),
    CONSTRAINT uq_email_usuario     UNIQUE (email),
    CONSTRAINT uq_documento         UNIQUE (numero_documento),
    CONSTRAINT fk_usuario_rol       FOREIGN KEY (id_rol) REFERENCES t_roles(id_rol)
) ENGINE=InnoDB;

INSERT INTO t_usuarios VALUES
    (NULL, 'CC', '1000000001', 'Carlos Ruiz',       'carlos.ruiz@basecamas.com',    '123456', '+57 301 000 0001', NULL, NOW(), 1, 2),
    (NULL, 'CC', '1000000002', 'Ana Silva',          'ana.silva@basecamas.com',      '123456', '+57 301 000 0002', NULL, NOW(), 1, 2),
    (NULL, 'CC', '1000000003', 'Pedro Martínez',     'pedro.martinez@basecamas.com', '123456', '+57 301 000 0003', NULL, NOW(), 1, 4),
    (NULL, 'CC', '1000000004', 'Luis Torres',        'luis.torres@basecamas.com',    '123456', '+57 301 000 0004', NULL, NOW(), 1, 4),
    (NULL, 'CC', '1000000005', 'Juan Pérez',         'juan.perez@basecamas.com',     '123456', '+57 301 000 0005', NULL, NOW(), 1, 3),
    (NULL, 'CC', '1000000006', 'María González',     'maria.gonzalez@basecamas.com', '123456', '+57 301 000 0006', NULL, NOW(), 1, 3),
    (NULL, 'CC', '1000000007', 'Laura Rodríguez',    'laura.rodriguez@basecamas.com','123456', '+57 301 000 0007', NULL, NOW(), 1, 1);


-- ============================================================
-- TABLA: t_clientes
-- Datos del cliente asociado a cada pedido
-- ============================================================
CREATE TABLE IF NOT EXISTS t_clientes (
    id_cliente          INT(11)         AUTO_INCREMENT  NOT NULL,
    nombre              VARCHAR(100)                    NOT NULL,
    cedula              VARCHAR(20)                     NOT NULL,
    telefono            VARCHAR(20)                     NOT NULL,
    email               VARCHAR(200),
    direccion           VARCHAR(255),
    localidad           VARCHAR(100),
    metodo_de_pago      VARCHAR(50),
    fecha_registro      DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_cliente       PRIMARY KEY (id_cliente),
    CONSTRAINT uq_cedula        UNIQUE (cedula)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_productos
-- Catálogo de productos (camas, espaldares, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS t_productos (
    id_producto         INT(11)         AUTO_INCREMENT  NOT NULL,
    medida              VARCHAR(50)                     NOT NULL,   -- ej: 140x190
    diseno              VARCHAR(100)                    NOT NULL,   -- diseño del espaldar
    descripcion         VARCHAR(255),
    tipo_producto       VARCHAR(100),                               -- ej: Cama completa, Base, etc.
    color               VARCHAR(80),
    tipo_tela           VARCHAR(80),
    precio              DECIMAL(12,2)                   NOT NULL,
    fecha_creacion      DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado              TINYINT(1)                      NOT NULL DEFAULT 1,
    CONSTRAINT pk_producto      PRIMARY KEY (id_producto)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_configuracion_comisiones
-- Porcentaje de comisión vigente (evita hardcodear el 8%)
-- ============================================================
CREATE TABLE IF NOT EXISTS t_configuracion_comisiones (
    id_config               INT(11)         AUTO_INCREMENT  NOT NULL,
    porcentaje_comision     DECIMAL(5,2)                    NOT NULL DEFAULT 8.00,
    fecha_vigencia          DATE                            NOT NULL,
    creado_por              INT(11)                         NOT NULL,
    CONSTRAINT pk_config_comision       PRIMARY KEY (id_config),
    CONSTRAINT fk_config_usuario        FOREIGN KEY (creado_por) REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;

INSERT INTO t_configuracion_comisiones VALUES (NULL, 8.00, CURDATE(), 7);


-- ============================================================
-- TABLA: t_pedidos
-- Pedido principal creado por el Asesor Comercial
-- Incluye campos de verificación, confirmación, envío e imagen
-- ============================================================
CREATE TABLE IF NOT EXISTS t_pedidos (
    id_pedido               INT(11)         AUTO_INCREMENT  NOT NULL,
    codigo_pedido           VARCHAR(20)                     NOT NULL,   -- ej: RM-00001
    fecha_pedido            DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Relaciones principales
    id_usuario              INT(11)                         NOT NULL,   -- Asesor que crea el pedido
    id_cliente              INT(11)                         NOT NULL,
    id_producto             INT(11)                         NOT NULL,

    -- Valores económicos
    valor_total             DECIMAL(12,2)                   NOT NULL,
    valor_envio             DECIMAL(12,2)                   NOT NULL DEFAULT 0.00,
    -- Nota: el valor_envio NO genera comisión

    -- Entrega
    horario_entrega         VARCHAR(100),
    direccion_entrega       VARCHAR(255),
    observaciones           TEXT,

    -- Imagen de referencia (URL/ruta; ver también t_imagenes_referencia para múltiples)
    foto_referencia         VARCHAR(255),

    -- Flujo de verificación y confirmación
    verificado              TINYINT(1)                      NOT NULL DEFAULT 0,
    fecha_verificacion      DATETIME,

    confirmado              TINYINT(1)                      NOT NULL DEFAULT 0,
    confirmado_por          INT(11),                                    -- FK a t_usuarios
    fecha_confirmacion      DATETIME,

    -- Estado general del pedido
    estado                  ENUM(
                                'pendiente_verificacion',
                                'pendiente_confirmacion',
                                'confirmado',
                                'en_produccion',
                                'listo_entrega',
                                'entregado',
                                'cancelado'
                            )                               NOT NULL DEFAULT 'pendiente_verificacion',

    fecha_actualizacion     DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_pedido                PRIMARY KEY (id_pedido),
    CONSTRAINT uq_codigo_pedido         UNIQUE (codigo_pedido),
    CONSTRAINT fk_pedido_asesor         FOREIGN KEY (id_usuario)    REFERENCES t_usuarios(id_usuario),
    CONSTRAINT fk_pedido_cliente        FOREIGN KEY (id_cliente)    REFERENCES t_clientes(id_cliente),
    CONSTRAINT fk_pedido_producto       FOREIGN KEY (id_producto)   REFERENCES t_productos(id_producto),
    CONSTRAINT fk_pedido_confirmador    FOREIGN KEY (confirmado_por) REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_imagenes_referencia
-- Imágenes de referencia adjuntas a un pedido
-- Permite múltiples imágenes por pedido, con opción de descarga
-- ============================================================
CREATE TABLE IF NOT EXISTS t_imagenes_referencia (
    id_imagen           INT(11)         AUTO_INCREMENT  NOT NULL,
    id_pedido           INT(11)                         NOT NULL,
    url_imagen          VARCHAR(500)                    NOT NULL,
    nombre_archivo      VARCHAR(255)                    NOT NULL,
    tipo_archivo        VARCHAR(20),                                -- jpg, png, etc.
    fecha_subida        DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subida_por          INT(11)                         NOT NULL,
    CONSTRAINT pk_imagen            PRIMARY KEY (id_imagen),
    CONSTRAINT fk_imagen_pedido     FOREIGN KEY (id_pedido)     REFERENCES t_pedidos(id_pedido),
    CONSTRAINT fk_imagen_usuario    FOREIGN KEY (subida_por)    REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_asignacion_produccion
-- Asignación de un pedido a un tapicero (usuario con rol Fabricación)
-- Maneja los 3 estados de producción del sistema
-- ============================================================
CREATE TABLE IF NOT EXISTS t_asignacion_produccion (
    id_asignacion           INT(11)         AUTO_INCREMENT  NOT NULL,
    id_pedido               INT(11)                         NOT NULL,
    id_tapicero             INT(11)                         NOT NULL,   -- usuario con rol Fabricación
    fecha_asignacion        DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_finalizacion      DATETIME,
    etapa_produccion        ENUM(
                                'tapicero',
                                'control_calidad',
                                'listo_entrega'
                            )                               NOT NULL DEFAULT 'tapicero',
    notas_produccion        TEXT,
    estado_produccion       TINYINT(1)                      NOT NULL DEFAULT 1,
    CONSTRAINT pk_asignacion            PRIMARY KEY (id_asignacion),
    CONSTRAINT fk_asignacion_pedido     FOREIGN KEY (id_pedido)     REFERENCES t_pedidos(id_pedido),
    CONSTRAINT fk_asignacion_tapicero   FOREIGN KEY (id_tapicero)   REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_comisiones_asesor
-- Comisiones generadas por pedido para cada asesor
-- El cálculo se basa en valor_total del pedido (sin valor_envio)
-- ============================================================
CREATE TABLE IF NOT EXISTS t_comisiones_asesor (
    id_comision             INT(11)         AUTO_INCREMENT  NOT NULL,
    id_pedido               INT(11)                         NOT NULL,
    id_asesor               INT(11)                         NOT NULL,
    porcentaje_comision     DECIMAL(5,2)                    NOT NULL DEFAULT 8.00,
    monto_calculado         DECIMAL(12,2)                   NOT NULL,   -- valor_total * porcentaje (sin envío)
    estado_pago             ENUM('pendiente', 'pagado', 'retenido')
                                                            NOT NULL DEFAULT 'pendiente',
    fecha_calculo           DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_pago              DATETIME,
    CONSTRAINT pk_comision              PRIMARY KEY (id_comision),
    CONSTRAINT uq_comision_pedido       UNIQUE (id_pedido),             -- una comisión por pedido
    CONSTRAINT fk_comision_pedido       FOREIGN KEY (id_pedido)     REFERENCES t_pedidos(id_pedido),
    CONSTRAINT fk_comision_asesor       FOREIGN KEY (id_asesor)     REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: T_FACTURA
-- Registro de pago/factura asociado a un pedido
-- ============================================================
CREATE TABLE IF NOT EXISTS T_FACTURA (
    id_ingreso          INT(11)         AUTO_INCREMENT  NOT NULL,
    metodo_pago         VARCHAR(50)                     NOT NULL,
    monto_ingreso       DECIMAL(12,2)                   NOT NULL,
    referencia_pago     VARCHAR(100),
    fecha_registro      DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_pedido           INT(11)                         NOT NULL,
    CONSTRAINT pk_factura           PRIMARY KEY (id_ingreso),
    CONSTRAINT fk_factura_pedido    FOREIGN KEY (id_pedido) REFERENCES t_pedidos(id_pedido)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: T_DETALLE_FACTURA
-- Detalle de los productos incluidos en una factura
-- ============================================================
CREATE TABLE IF NOT EXISTS T_DETALLE_FACTURA (
    id_detalle          INT(11)         AUTO_INCREMENT  NOT NULL,
    cantidad            INT(11)                         NOT NULL DEFAULT 1,
    precio_unitario     DECIMAL(12,2)                   NOT NULL,
    subtotal            DECIMAL(12,2)                   NOT NULL,
    id_pedido           INT(11)                         NOT NULL,
    id_producto         INT(11)                         NOT NULL,
    CONSTRAINT pk_detalle_factura           PRIMARY KEY (id_detalle),
    CONSTRAINT fk_detalle_pedido            FOREIGN KEY (id_pedido)     REFERENCES t_pedidos(id_pedido),
    CONSTRAINT fk_detalle_producto          FOREIGN KEY (id_producto)   REFERENCES t_productos(id_producto)
) ENGINE=InnoDB;


-- ============================================================
-- TABLA: t_historial_estados_pedido
-- Auditoría completa de todos los cambios de estado de un pedido
-- Permite rastrear quién cambió qué y cuándo
-- ============================================================
CREATE TABLE IF NOT EXISTS t_historial_estados_pedido (
    id_historial        INT(11)         AUTO_INCREMENT  NOT NULL,
    id_pedido           INT(11)                         NOT NULL,
    estado_anterior     VARCHAR(50),
    estado_nuevo        VARCHAR(50)                     NOT NULL,
    cambiado_por        INT(11)                         NOT NULL,
    fecha_cambio        DATETIME                        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacion         TEXT,
    CONSTRAINT pk_historial             PRIMARY KEY (id_historial),
    CONSTRAINT fk_historial_pedido      FOREIGN KEY (id_pedido)     REFERENCES t_pedidos(id_pedido),
    CONSTRAINT fk_historial_usuario     FOREIGN KEY (cambiado_por)  REFERENCES t_usuarios(id_usuario)
) ENGINE=InnoDB;