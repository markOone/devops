# Лабораторна робота №4: IaC. Terraform. Ansible

## Структура репозиторію
* `/terraform` - конфігураційні файли для розгортання інфраструктури (провайдер libvirt/qemu).
* `/ansible` - конфігурація для налаштування ВМ (inventory та playbook).

## Інструкція із запуску

### 1. Provisioning (Terraform)
Для автоматичного розгортання двох віртуальних машин (worker та db) перейдіть у директорію `terraform` та виконайте команди:
```bash
cd terraform
terraform init
terraform apply -auto-approve
```
Після виконання команди Terraform виведе IP-адреси створених машин.

### 2. Configuration Management (Ansible)
Після створення інфраструктури, переконайтеся, що IP-адреси у файлі ansible/inventory.ini відповідають вашим ВМ. Для налаштування серверів (встановлення Nginx, PostgreSQL, створення користувачів та налаштування прав) перейдіть у директорію ansible та запустіть процес:
```bash
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml
```