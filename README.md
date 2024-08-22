# Runners

This project deploys a non-ephemeral self-hosted GitHub runner(s) based on Rocky Linux VM.

Runners will join an organization and thus could be available for any repo in the organization.

- `.github` - contains a few workflows to test configured self-hosted runners.
- `110-Infrastructure_terraform` - contains terraform code to deploy VM(s) and generate an inventory file for ansible.
- `120-Configuration_ansible` - contains a play to deploy GHA runner software, create cleanup scripts, and install additional packages.
- `secrets.list` - lists Vault secrets required for successful deployment.

## Check GitHub organization settings

We need to generate a personal token, that will allow registration of self-hosted runners. URLs in the examples below are specific to an organization called `graysievert-lab`, but could be easily adapted for any other.

Go to the organization's `Settings` at `https://github.com/organizations/graysievert-lab/settings/profile`

Then navigate to `Third-party Access->` `Personal access tokens->` `settings` at `https://github.com/organizations/graysievert-lab/settings/personal-access-tokens` and ensure that `Allow access via fine-grained personal access tokens` is `on`.

Then go to `Actions->` `General` at `https://github.com/organizations/graysievert-lab/settings/actions` and ensure that `Fork pull request workflows from outside collaborators` is set to `Require approval for all outside collaborators`.

Then go to `Actions->` `Runner groups->` `Default` at `https://github.com/organizations/graysievert-lab/settings/actions/runner-groups/1` and check against `Allow public repositories`

**WARNING**:  Allowing self-hosted runners on public repositories and allowing workflows on public forks introduces a significant security risk. [Read more.](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)

Now return to your personal GitHub profile and navigate to profile settings: `https://github.com/settings/profile`.

Then go to `Developer settings->` `Personal access tokens->` `Fine-grained tokens` at `https://github.com/settings/tokens?type=beta`

Issue a fine-grained token with organization read/write permission `Self-hosted runners`.

In the example below, the token is stored in Vault at `infra-gha/selfhosted_runners` as key-value pair `PERSONAL_ACCESS_TOKEN`.

## Initialize environment

Note: All commands in this readme (unless stated otherwise) are expected to run from the repo's root directory.

Generate SSH keys:

```bash
$ ssh-keygen -q  -C "" -N "" -f $HOME/.ssh/iac
$ ssh-keygen -q  -C "" -N "" -f $HOME/.ssh/vm
```

Set env variables:

```bash
$ eval $(ssh-agent -s)
$ export VAULT_ADDR=https://aegis.lan:8200
$ vault login -method=oidc
```

Generate the API token and sign the SSH key to access Proxmox:

```bash
$ source ./prime_proxmox_secrets.sh $HOME/.ssh/iac
```

Initialize providers and execute configuration:

NOTE: To set the number of runners check th local variable `runners_quantity` in `main.tf`.

```bash
$ terraform -chdir=110-Infrastructure_terraform init
$ terraform -chdir=110-Infrastructure_terraform plan
$ terraform -chdir=110-Infrastructure_terraform apply
```

When the VM is ready, sign the second SSH key and test the VM's accessibility.

```bash
$ ./sign_ssh_vm_key.sh $HOME/.ssh/vm
$ ssh rocky@gha-1.lan uname -a
...
```

Install ansible requirements:

```bash
$ ansible-galaxy install -r 120-Configuration_ansible/ansible-requirements.yaml
```

and proceed to:

## `play-01-install-gha.yaml`

This play:

- Looks up in Vault a GitHub personal token for runners management
- Configures VM(s) created by Terraform to become organizational self-hosted runners
- Installs additional packages and cleanup scripts

To run the book execute the following:

```bash
$ ANSIBLE_CONFIG=120-Configuration_ansible/ansible.cfg \
ansible-playbook -v 120-Configuration_ansible/play-01-install-gha.yaml
```

After the play is finished visit `https://github.com/organizations/graysievert-lab/settings/actions/runners` and check if your runner(s) appeared.

## Testing

To test the runner's operation go to `Actions` and run workflow `Check Self-hosted runner`.

To delete old runs use workflow `Delete old workflow runs`
