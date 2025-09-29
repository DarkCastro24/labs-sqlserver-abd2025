INICIO SECCION PREREQUISITOS
-- El primer paso para la practica vamos a iniciar sesion en SQL Server Management Studio con un usuario que tenga permisos de administrador en este caso 
-- utilizaremos el usuario "sa" (System Administrator) que es el administrador por defecto que viene en SQL Server.*/

COLOCA ESTO EN BLOQUE VERDE
-- Importante: Es importante iniciar sesion con el usuario "sa" para tener todos los permisos de administrador
-- lo que nos puede evitar problemas de privilegios.
-- EN CASO DE QUE NO CUENTES CON EL LOGIN "sa", INICIA SESION CON WINDOWS AUTHENTICATION PERO PUEDES TENER PROBLEMAS DE PERMISOS 
FIN DEL BLOQUE VERDE

COLOCA ESTO COMO TITULO 
-- Crear la base de datos con sus tablas e inserciones 
INICIO BLOQUE DE CODIGO
-- 1. Confirmar base de datos de trabajo; crear si no existe.
IF DB_ID(N'DB_Gimnasio') IS NULL
BEGIN
    PRINT 'Creando base de datos DB_Gimnasio...';
    CREATE DATABASE DB_Gimnasio;
END
GO

-- 2. Crear tablas de la base de datos DB_Gimnasio
USE DB_Gimnasio;

-- Tabla Cliente
IF OBJECT_ID(N'dbo.Cliente', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cliente (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        email  NVARCHAR(100) NULL,
        fecha_alta DATE NOT NULL DEFAULT (GETDATE())
    );
INSERT INTO dbo.Cliente(nombre,email) 
VALUES ('Ana Pérez','ana@fit.com'),('Luis Díaz','luis@fit.com'),('María López','maria@fit.com'); 
END

-- Tabla Membresia
IF OBJECT_ID(N'dbo.Membresia', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Membresia (
        id INT IDENTITY(1,1) PRIMARY KEY,
        cliente_id INT NOT NULL,
		plan_membresia NVARCHAR(40) NOT NULL, 
        fecha_inicio DATE NOT NULL DEFAULT (GETDATE()),
        fecha_fin    DATE NULL,
        CONSTRAINT FK_Membresia_Cliente FOREIGN KEY (cliente_id) REFERENCES dbo.Cliente(id)
    );
	  INSERT INTO dbo.Membresia(cliente_id,plan_membresia,fecha_inicio,fecha_fin) 
	  VALUES (1,'Mensual','2025-08-01',NULL),(2,'Trimestral','2025-07-15','2025-10-14'); 
END
FIN DEL BLOQUE DE CODIGO 

FIN SECCION PREREQUISITOS


INICIO SECCION CREACION DE LOGINS Y USUARIOS  

AGREGA ESTO COMO TITULO 
-- A continuación, aprenderemos a crear los logins y usuarios necesarios para la práctica.

AGREGAR LAS SIGUIENTES LINEAS COMO LISTA
-- Crear el LOGIN SQL para perfil de analítica 
-- Los LOGIN se crean en la base de datos "master"
-- debido a que se crean a nivel de servidor.
-- El uso de IF NOT EXISTS es opcional es para validar que no exista el login o usuario

INICIO BLOQUE DE CODIGO
-- Nos cambiamos a la base master
USE [master]
GO

-- Validando que no exista ya un login llamado orange
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'orange')
BEGIN
    CREATE LOGIN [orange] 
    WITH PASSWORD = 'UCA@2025', 
    CHECK_POLICY = ON,          
    CHECK_EXPIRATION = ON;      
END
ELSE 
	PRINT 'Ya existe el Login "orange"'
GO
FIN DEL BLOQUE DE CODIGO

COLOCA ESTO COMO TITULO 
-- Buenas practicas de seguridad recomendadas al crear logins
COLOCA ESTO COMO LISTA
-- WITH PASSWORD = 'UCA@2025', -- Definimos la contraseña inicial
-- CHECK_POLICY = ON,          -- Aplica políticas de seguridad de Windows (longitud, complejidad, intentos fallidos)
-- CHECK_EXPIRATION = ON;      -- La contraseña expira según política de Windows

COLOCA ESTO COMO TITULO
-- Crear el login sin validar existencia previa
INICIO BLOQUE DE CODIGO
CREATE LOGIN [orange] 
    WITH PASSWORD = 'UCA@2025', 
    CHECK_POLICY = ON,         
    CHECK_EXPIRATION = ON;     
FIN DEL BLOQUE DE CODIGO

COLOCA ESTO EN BLOQUE VERDE
-- IMPORTANTE!!: Este login orange está pensado para el rol analítica, es decir un usuario que solo leerá datos sin modificarlos.

COLOCA ESTO COMO TITULO
-- Crear usuario en la base de datos DB_Gimnasio para el login orange

INICIO BLOQUE DE CODIGO
-- Tenemos que conectarnos a la base de datos donde trabajaremos
USE DB_Gimnasio;

-- Creamos el usuario "orange" a partir del login "orange"
-- Esto permite que el login pueda acceder específicamente a la base "DB_Gimnasio"

-- Validamos si ya existe el usuario
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'orange')
BEGIN
    CREATE USER [orange] FOR LOGIN [orange];
END
ELSE
	PRINT 'Ya existe el usuario "orange" en DB_Gimnasio'
GO

-- Creamos el usuario sin validar que ya exista
CREATE USER [orange] FOR LOGIN [orange];
FIN DEL BLOQUE DE CODIGO

COLOCAR ESTO EN BLOQUE VERDE
-- Ahora el login orange ya puede acceder a DB_Gimnasio como usuario orange

COLOCAR ESTO COMO TITULO
-- Ahora vamos a crear un LOGIN para la aplicación app_gym

INICIO BLOQUE
USE [master];

-- Verificamos que no exista el login
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'app_gym')
BEGIN
    PRINT 'Creando LOGIN [app_gym]';
    CREATE LOGIN [app_gym] 
    WITH PASSWORD = 'UCA@2025', -- Contraseña inicial
    CHECK_EXPIRATION = OFF, -- La clave nunca expira 
    CHECK_POLICY = ON; -- Se valida que la contraseña cumpla reglas de seguridad de Windows 
END
ELSE
	PRINT 'Ya existe el login "app_gym" en DB_Gimnasio'
GO

-- Creamos el login sin validar que ya exista
CREATE LOGIN [app_gym] 
   WITH PASSWORD = 'UCA@2025',
   CHECK_EXPIRATION = OFF, 
   CHECK_POLICY = ON; 
FIN DEL BLOQUE DE CODIGO

COLOCA ESTO COMO TITULO
-- Ahora vamos a crear el usuario app_gym en la base de datos DB_Gimnasio

INICIO BLOQUE DE CODIGO
-- Crear el usuario en DB_Gimnasio para app_gym
USE DB_Gimnasio;

-- Creamos el usuario app_gym dentro de la base de datos
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'app_gym')
BEGIN
    CREATE USER [app_gym] FOR LOGIN [app_gym];
END
ELSE
	PRINT 'Ya existe el usuario "orange" en DB_Gimnasio'
GO

-- Creamos el usuario app_gym sin validar que ya exista
CREATE USER [app_gym] FOR LOGIN [app_gym];
FIN DEL BLOQUE DE CODIGO

FIN DE LA SECCION CREACION DE LOGINS Y USUARIOS

INICIO
/** ROLES Y PERMISOS **/

COLOCA ESTO COMO TITULO 
-- En SQL Server, los roles son grupos de permisos. 
-- En lugar de asignar permisos a cada usuario directamente

INICIO DE BLOQUE DE CODIGO
-- Crear un rol de solo lectura (db_lectura)
-- Creamos el rol "db_lectura" que servirá para usuarios con acceso solo de lectura
USE DB_Gimnasio;

-- Creamos rol "db_lectura" validando existencia
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_lectura')
BEGIN
    CREATE ROLE db_lectura;
END
ELSE
	PRINT 'Ya existe el role "db_lectura" en DB_Gimnasio'

-- Creamos rol "db_lectura" sin validar existencia 
CREATE ROLE db_lectura;

-- Otorgamos permiso de SELECT (solo lectura) sobre TODO el esquema dbo
GRANT SELECT ON SCHEMA::dbo TO db_lectura;

-- Hacemos miembro del rol "db_lectura" al usuario orange (perfil analítica solo lectura)
EXEC sp_addrolemember 'db_lectura', 'orange';
GO
FIN DEL BLOQUE DE CODIGO

COLOCA ESTO COMO TITULO
-- Ahora crearemos un rol para la aplicación que tendrá permisos más amplios

INICIO BLOQUE DE CODIGO
-- Crear un rol para la aplicación (db_app)
-- Creamos el rol "db_app" que servirá para la aplicación del gimnasio
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_app')
BEGIN
    PRINT 'Creando ROLE [db_app]...';
    CREATE ROLE db_app;
END
ELSE
	PRINT 'Ya existe el role "db_app" en DB_Gimnasio'

-- Creamos rol sin validar existencia 
CREATE ROLE db_app;

-- Otorgamos permisos específicos sobre las tablas de interés:
-- La aplicación podrá leer, insertar y actualizar clientes y membresías.
GRANT SELECT, INSERT, UPDATE ON dbo.Cliente   TO db_app;
GRANT SELECT, INSERT, UPDATE ON dbo.Membresia TO db_app;

-- Asignamos al usuario "app_gym" como miembro del rol db_app
EXEC sp_addrolemember 'db_app','app_gym';
GO
FIN DEL BLOQUE DE CODIGO

COLOCAR ESTO COMO TITULO
-- Denegar acciones peligrosas: Incluso si un rol o usuario llegara a tener permisos más amplios en el futuro, podemos blindar ciertas acciones con DENY

COLOCAR COMO BLOQUE DE CODIGO
-- Negamos la posibilidad de borrar clientes
DENY DELETE ON dbo.Cliente TO db_app;

-- Negamos la posibilidad de alterar el esquema dbo 
DENY ALTER ON SCHEMA::dbo TO db_app;
GO
FIN DEL BLOQUE DE CODIGO

FIN DE LA SECCION ROLES Y PERMISOS

INICIO DE LA SECCION COMPROBACION DE PERMISOS
/**	COMPROBACION DE PERMISOS **/

COLOCAR COMO TITULO
-- Una vez creados los logins, usuarios y roles, debemos probar que los permisos funcionan como esperamos.
-- ¿Sera que app_gym puede borrar clientes? 

INICIO BLOQUE DE CODIGO
-- Probar que app_gym NO puede borrar clientes
USE DB_Gimnasio;

-- Ejecutamos las sentencias como app_gym
EXECUTE AS USER = 'app_gym';

-- Intentamos borrar un cliente (Deberia fallar porque no tiene permiso)
DELETE FROM dbo.Cliente WHERE id = 1;

-- Regresamos al contexto original (Usuario con el que iniciamos sesion al abrir SQL Server)
REVERT;
GO
FIN DEL BLOQUE DE CODIGO

COLOCAR COMO TITULO
-- Probar que app_gym sí puede insertar y actualizar

INICIO BLOQUE DE CODIGO
-- Ejecutamos la sentencia como app_gym
EXECUTE AS USER = 'app_gym';

-- Insertamos un nuevo cliente (Debe funcionar)
INSERT INTO dbo.Cliente (nombre, email)
VALUES (N'James Humberstone', N'james@gmail.com');

SELECT * FROM dbo.Cliente WHERE email = 'james@gmail.com';

-- Guardamos el id del ultimo cliente ingresado (Debe funcionar)
DECLARE @ultimoID INT = (SELECT max(id) FROM dbo.Cliente);

UPDATE dbo.Cliente
SET email = N'james@uca.edu.sv'
WHERE id = @ultimoID;

-- Comprobamos se actualizo el correo del cliente
SELECT * FROM dbo.Cliente WHERE email = 'james@uca.edu.sv';

-- Regresamos al contexto original (Obligatorio para cambiar de usuario)
REVERT;
GO

-- Opcional: Comprobamos que regresamos al contexto original 
SELECT USER_NAME() AS UsuarioDBActual, ORIGINAL_LOGIN() AS LoginOriginal;
FIN DEL BLOQUE DE CODIGO

COLOCAR ESTO EN BLOQUE VERDE
-- Importante: UsuarioDBActual deberia ser dbo y no app_gym

COLOCAR ESTO COMO TITULO
-- Probar que orange solo puede leer

INICIO BLOQUE DE CODIGO
--- PRUEBA: ¿Sera que orange tiene solo lectura en esquema dbo? (INSERT debe FALLAR) 
EXECUTE AS USER = 'orange';

-- Lectura permitida: debe funcionar en las tablas Cliente y Membresia 
SELECT TOP(1) * FROM dbo.Cliente;
SELECT TOP(1) * FROM dbo.Membresia;

-- Intentamos insertar (debe fallar)
INSERT INTO dbo.Cliente (nombre) VALUES (N'Eduardo Castro');

-- Regresamos al contexto original (Usuario con el que iniciamos sesion)
REVERT;
GO
FIN DEL BLOQUE DE CODIGO

COLOCAR ESTO EN BLOQUE VERDE
-- Tambien podemos consultar los permisos efectivos de un usuario

INICIO BLOQUE DE CODIGO
-- Primero verificamos con que usuario estamos activos en la base de datos 
SELECT USER_NAME() AS UsuarioDBActual, ORIGINAL_LOGIN() AS LoginOriginal;

-- Consultamos los permisos del usuario db actual en la base DB_Gimnasio
SELECT * 
FROM fn_my_permissions(NULL,'DATABASE');
GO

-- Podemos hacer la prueba con el otro usuario creado 
EXECUTE AS USER = 'app_gym';

-- Consultamos los permisos del usuario app_gym en la base DB_Gimnasio
SELECT * 
FROM fn_my_permissions(NULL,'DATABASE');
GO
FIN DEL BLOQUE DE CODIGO

fin de la seccion COMPROBACION DE PERMISOS

inicio de la seccion BUENAS PRACTICAS
/** PARTE D: EJEMPLOS DE BUENAS PRACTICAS **/

colocar esto como titulo
-- A continuación, se presentan algunas buenas prácticas al crear logins y usuarios en SQL Server

colocar como titulo
/** Contraseñas seguras **/

inicio bloque de codigo
CREATE LOGIN usuario_seguro 
WITH PASSWORD = 'CLaVeS3gura@2025!',  -- Cumple con la complejidad de las politicas 
     CHECK_POLICY = ON;          -- Aplica politicas de seguridad 
GO

/** Rotación de contraseñas **/
CREATE LOGIN usuario_rotacion
WITH PASSWORD = 'R0taci0n$2025',
     CHECK_POLICY = ON,          
     CHECK_EXPIRATION = ON;      -- La contraseña expira tras cierto tiempo (Rotacion)
GO
fin del bloque de codigo

colocar esto como titulo
/** Principio de menor privilegio. **/

inicio bloque de codigo
-- Crear usuario desde un login existente
CREATE USER lector FOR LOGIN usuario_seguro;

-- Asignar solo permisos necesarios para el funcionamiento del usuario en este caso de lectura en una tabla específica
GRANT SELECT ON dbo.Cliente TO lector;
fin del bloque de codigo

colocar esto como titulo
/** Uso de roles en lugar de asignar permisos a usuarios individuales. **/

inicio bloque de codigo
-- Crear rol de solo lectura
CREATE ROLE soloLectura;

-- Conceder permisos de lectura a todas las tablas del esquema dbo
GRANT SELECT ON SCHEMA::dbo TO soloLectura;

-- Agregar usuarios al rol
EXEC sp_addrolemember 'soloLectura', 'lector';
EXEC sp_addrolemember 'soloLectura', 'usuario_rotacion';
fin del bloque de codigo

/*	FIN DEL EJERCICIO GUIADO	*/

/**	OPCIONAL: SCRIPT DE LIMPIEZA PARA BORRAR OBJETOS DE LA PRÁCTICA **/

colocar esto como titulo
-- A continuación, se presenta un script para eliminar los logins, usuarios, roles y tablas creadas durante la práctica.

inicio bloque de codigo
-- Muestra el login de servidor con el que entraste a SQL Server (LOGIN)
SELECT SUSER_NAME() AS LoginActual, SUSER_SNAME() AS LoginSName, SYSTEM_USER AS SystemUser;

-- Mostrar que usuario y que login esta actualmente activo (USER)
SELECT USER_NAME() AS UsuarioDBActual, ORIGINAL_LOGIN() AS LoginOriginal;

USE DB_Gimnasio;

-- Revocar permisos para los roles
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_lectura')
    REVOKE SELECT ON SCHEMA::dbo FROM db_lectura;

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'db_app')
BEGIN
    REVOKE SELECT, INSERT, UPDATE ON dbo.Cliente   FROM db_app;
    REVOKE SELECT, INSERT, UPDATE ON dbo.Membresia FROM db_app;
    DENY DELETE ON dbo.Cliente TO db_app;
    DENY ALTER  ON SCHEMA::dbo TO db_app;
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'reportes')
BEGIN
    REVOKE SELECT ON SCHEMA::dbo FROM reportes;
    DENY ALTER ON SCHEMA::dbo TO reportes;
END

-- Borrar usuarios 
DROP USER IF EXISTS orange;
DROP USER IF EXISTS analista;
DROP USER IF EXISTS app_gym;

-- Borrar roles 
DROP ROLE IF EXISTS db_lectura;
DROP ROLE IF EXISTS db_app;
DROP ROLE IF EXISTS reportes;

-- Borrar tablas de práctica (si existen)
DROP TABLE IF EXISTS dbo.Membresia;
DROP TABLE IF EXISTS dbo.Cliente;
DROP TABLE IF EXISTS dbo.Trabajador;

-- Borrar logins a nivel servidor 
USE [master];

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'orange')
    DROP LOGIN orange;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'app_gym')
    DROP LOGIN app_gym;

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'analista')
    DROP LOGIN analista;
GO
fin del bloque de codigo