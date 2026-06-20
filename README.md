# posweb2026

Para executar essa tarefa, foi utilizado o copilot com claude sonnet 4.6.

A interação com a IA ocorreu da seguinte forma:
1. Primeiro, pedi para a IA me explicar a arquitetura do projeto
	o arquivo user_data.tpl apenas instalava as dependências
	
2. Pedi para a IA atualizar o script user_data.tpl para fazer o deploy do código	
	o agente entendeu que o deploy seria feito apenas através desse script
	
3. Especifiquei que o código da infra seria executado localmente, mas o deploy seria feito pela action do github
	aqui o agente entendeu que o servidor backend e o banco estão separados, sendo que o banco fica configurado no RDS
	então ele atualizou do user_data.tpl para instalar dependencias, configurar nginx (front), systemd (back)
	atualizou o workflow para substituir os placeholders, fazer o deploy, reiniciar o serviço e executar a cada push

    Foi necessário incluir as seguintes secrets no repositorio:
    HOST:	IP público do EC2 (terraform output ec2_public_ip);
    USERNAME:	ubuntu;
    DB_HOST:	endpoint do RDS (terraform output rds_endpoint);
    DB_NAME:	myapp;
    DB_USERNAME:	myapp_user;
    DB_PASSWORD:	myapp_passwd.

4. Executei o terraform pela primeira vez e deu o erro groupId is invalid
	a IA sugeriu que o atributo security_groups = em main.tf aceita strings mas só funciona no EC2 classic
	sugeriur trocar por vpc_security_group_ids, que aceita IDs 

5. Fiz as alterações e executei o terraform novamente. Agora deu o erro The key pair 'posweb-myapp-2026' does not exist
	para criar a chave ssh, o agente sugeriu adicionar no próprio código do terraform, mas avisou que não é o idela para ambiente de produção (criou keypair.tf)
	
6. Executei o workflow de deploy do backend deu erro can't connect without a private SSH key or password na action
	isso ocorreu porque faltou incluir o campo environment: prd no workflow

7. Depois, o workflow de deploy do front deu erro index.html: Cannot open: Permission denied
	aqui foi preciso incluir chown -R ubuntu:ubuntu /home/ubuntu/myapp no user_data.tpl para corrigir esse erro em futuras instâncias e o seguinte workflow para corrigir a instância atual:
	- name: Prepare web root
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.KEY }}
          script: sudo chown ubuntu:ubuntu /var/www/html
          
         o que não ficou claro é que esse step foi adicionado após o deploy do front, que era justamente onde o erro ocorreu
 
 8. Depois, acessei o front pelo endereço 13.222.172.188, mas ao tentar conectar no back, deu connection refused:
 	aqui, a solução foi trocar app.run(debug=True) por app.run(host='0.0.0.0', port=5000) em myapi.py
 	
9. Depois passou a dar erro 500 no back
	aqui foi porque não foi executado o arquivo db.sql para criar o schema no back. 
	foi necessário atualizar user_data.tpl para instalar o mysql-client
	depois foi adicionado step:
	- name: Setup DB schema
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.KEY }}
          script: |
            which mysql || sudo apt-get install -y mysql-client
            mysql -h ${{ secrets.DB_HOST }} \
                  -u ${{ secrets.DB_USERNAME }} \
                  -p${{ secrets.DB_PASSWORD }} \
                  ${{ secrets.DB_NAME }} \
                  -e "CREATE TABLE IF NOT EXISTS People (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(100), age INT, cell_phone VARCHAR(15));"

10. Por fim, removi o step Prepare web root, pois ele não é mais necessário
