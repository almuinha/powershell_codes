#---------------------------------------------#
# VARIÁVEIS PARA CONEXÃO COM O BANCO DE DADOS #
#---------------------------------------------#
#
[CmdletBinding()]
param (
    [string]$dbServerSource,
    [string]$dbNameSource,
    [string]$dbUserSource,
    [string]$dbPassSource,
    [string]$dbServerDest,
    [string]$dbNameDest,
    [string]$dbUserDest,
    [string]$dbPassDest
)
#
#---------------------#
# CERTIFICADO DIGITAL #
#---------------------#
wget https://www.site.com/file_name.crt.pem -OutFile file_name.crt.pem
#
#
#--------------------------------------------------------------------#
# CONSULTANDO DADOS EM TABELAS DE PRODUÇÃO E SALVANDO EM ARQUIVO CSV #
#--------------------------------------------------------------------#
echo "SELECT * FROM employees" | mysql -h $dbServerSource -u "$dbUserSource" "-p$dbPassSource" --ssl-ca=nome_do_arquivo.crt.pem $dbNameSource > prd_employees.csv
echo "SELECT * FROM products"  | mysql -h $dbServerSource -u "$dbUserSource" "-p$dbPassSource" --ssl-ca=nome_do_arquivo.crt.pem $dbNameSource > prd_products.csv
#
#
#------------------------------------------------------#
# ACESSANDO CONTEÚDO DOS ARQUIVOS ATRAVÉS DE VARIÁVEIS #
#------------------------------------------------------#
$employees = (Get-Content .\prd_employees.csv) -replace '\t',';' | ConvertFrom-Csv -Delimiter ';'
$products  = (Get-Content .\prd_products.csv) -replace '\t',';'  | ConvertFrom-Csv -Delimiter ';'
#
#
#----------------------------------------#
# INSERT DE DADOS EM TABELAS PROVISÓRIAS #
#----------------------------------------#
#
#----------------------------------#
# LIMPANDO A TABELA PROV_EMPLOYEES #
#----------------------------------#
echo "DELETE FROM prov_employees;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#----------------------------------------------#
# INSERINDO REGISTROS NA TABELA PROV_EMPLOYEES #
#----------------------------------------------#
$counter = 0;
foreach ($row in $employees)
        { 
            echo "INSERT INTO prov_employees
					(
						 employee_id
						,employee_name
						,employee_gender
						,employee_birth_date
						,employee_ssn
					)
				  VALUES
					(
						 CONVERT('" + $row.employee_id         + "', VARCHAR(15))
						,CONVERT('" + $row.employee_name       + "', VARCHAR(400))
						,CONVERT('" + $row.employee_gender     + "', VARCHAR(100))
						,CONVERT('" + $row.employee_birth_date + "', VARCHAR(10))
						,CONVERT('" + $row.employee_ssn        + "', VARCHAR(15))
                    );"
			| mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
            $counter +=1;
        }
#
#
#---------------------------------#
# LIMPANDO A TABELA PROV_PRODUCTS #
#---------------------------------#
echo "DELETE FROM prov_products;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#---------------------------------------------#
# INSERINDO REGISTROS NA TABELA PROV_PRODUCTS #
#---------------------------------------------#
$counter = 0;
foreach ($row in $employees)
        { 
            echo "INSERT INTO prov_products
					(
						 product_id
						,product_name
						,product_color
						,product_width
						,product_height
						,product_weight
						,product_material
					)
				  VALUES
					(
						 CONVERT('" + $row.product_id       + "', VARCHAR(15))
						,CONVERT('" + $row.product_name     + "', VARCHAR(300))
						,CONVERT('" + $row.product_color    + "', VARCHAR(100))
						,CONVERT('" + $row.product_width    + "', VARCHAR(10))
						,CONVERT('" + $row.product_height   + "', VARCHAR(10))
						,CONVERT('" + $row.product_weight   + "', VARCHAR(10))
						,CONVERT('" + $row.product_material + "', VARCHAR(200))
                    );"
			| mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
            $counter +=1;
        }
#
#
#---------------------------------------------------------------#
# INSERT DE DADOS NAS TABELAS DE DESTINO, COM OS DADOS TRATADOS #
#---------------------------------------------------------------#
#
#-------------------------------------#
# LIMPANDO A TABELA UPDATED_EMPLOYEES #
#-------------------------------------#
echo "DELETE FROM updated_employees;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#----------------------------------------------------------#
# INSERINDO REGISTROS TRATADOS NA TABELA UPDATED_EMPLOYEES #
#----------------------------------------------------------#
#
echo "INSERT INTO updated_employees
	  SELECT
		 CONVERT(REPLACE(RTRIM(employee_id), '+', ''), INT)                          AS Funcionarios_id
		,REPLACE(RTRIM(employee_name), '+', '')                                      AS secao_nome
		,REPLACE(RTRIM(employee_gender), '+', '')                                    AS secao_nome
		,CONVERT(REPLACE(RTRIM(employee_birth_date), '+', ''), DATETIME)             AS employee_birth_date
		,REPLACE(TRIM(CONVERT(REPLACE(RTRIM(employee_ssn), '+', ''), INT)), 0, NULL) AS Perfil_id
	FROM
		prov_employees;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#
#------------------------------------#
# LIMPANDO A TABELA UPDATED_PRODUCTS #
#------------------------------------#
echo "DELETE FROM updated_products;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#----------------------------------------------------------#
# INSERINDO REGISTROS TRATADOS NA TABELA UPDATED_EMPLOYEES #
#----------------------------------------------------------#
#
echo "INSERT INTO updated_products
	  SELECT
		 CONVERT(REPLACE(RTRIM(product_id), '+', ''), INT)                             AS product_id
		,REPLACE(RTRIM(product_name), '+', '')                                         AS product_name
		,REPLACE(RTRIM(product_color), '+', '')                                        AS product_color
		,REPLACE(TRIM(CONVERT(REPLACE(RTRIM(product_width), '+', ''), INT)), 0, NULL)  AS product_width
		,REPLACE(TRIM(CONVERT(REPLACE(RTRIM(product_height), '+', ''), INT)), 0, NULL) AS product_height
		,REPLACE(TRIM(CONVERT(REPLACE(RTRIM(product_weight), '+', ''), INT)), 0, NULL) AS product_weight
		,REPLACE(RTRIM(product_material), '+', '')                                     AS product_material
	FROM
		prov_products;" | mysql -h $dbServerDest -u "$dbUserDest" "-p$dbPassDest" --ssl-ca=file_name.crt.pem $dbNameDest
#
#