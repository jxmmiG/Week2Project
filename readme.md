# Project files
1. main.tf contains the resource deployment scripts
2. providers.tf contains the azurerm provider (intentionally kept separate from the code)
3. variables.tf contains the variable definition
4. variables.auto.tfvars contains the variable declaration

*****

documentation can be found in terraform registry
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

*****
As usual, you need to login to your Azure account using Azure CLI (you can do this from the VS code terminal)

Once you're signed in, intialize terraform, and you can run 
`terraform plan`
to confirm any changes you'll be making before committing them with 
`terraform apply -auto-approve`
