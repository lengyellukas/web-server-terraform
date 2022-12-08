
# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction

This project has a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Instructions

1. Server image is created by Packer. The packer template is a file with filename server.json.
2. Login to your Azure Login using Azure CLI by providing your credentials (in new browser window that opens automatically) after running command
	```
	az login
	```
3. To deploy Packer image to the Azure account, run from the project directory command
	```
	packer build "server.json"
	```
4. Once the packer image is deployed to your Azure Account, copy the value of **ManagedImageId** from the terminal output and use it as value of source_image_id present in the file main.tf
5. To deploy Terraform infrastructure, the commands below must be executed from the project directory. You can also choose the number of VMs created by adding a value for a variable **instance_count** when running terraform plan command. The default number is 2 and it can be changed in the file vars.tf under variable instance_count.
	```
	terraform init
	terraform validate
	terraform plan -out solution.plan (terraform plan -var="instance_count=3" -out solution.plan)
	terraform apply -auto-approve solution.plan
	```
6. If you do not need the deployed resources anymore, you can destroy them by running command:
	```
	terraform destroy
	```

### Output

1. After deploying Packer image, the details of the artifacts should be printed to the terminal. The output value that should be used in Terraform main.tf file is **ManagedImageId**.
2. After initiating Terraform, the output should confirmed that Terraform has been successfully initiated
3. If the Terraform validation was successful, Success message confirming that the configuration is valid should be printed out.
4. The Terraform plan will be stored in the file specified after -out flag.
5. Once the resources were deployed to Azure, the confirmation that Apply was completed will be printed out. The resources will be available also on Azure Portal.
