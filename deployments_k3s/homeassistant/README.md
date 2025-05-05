# Home Assistant

I actually just use the helm chart for now with my custom values file.

TODO Look at this again bc I might have to do something with renovate to make sure this stays up to date idk probably for the hook to redeploy through argocd
TODO look into esphome and use it as plugin with the container thingy

## Install

This will be added to argocd.

## Manual Install

I use this baseline: https://github.com/pajikos/home-assistant-helm-chart/tree/main

```bash
helm repo add pajikos http://pajikos.github.io/home-assistant-helm-chart/
helm repo update
helm install home-assistant pajikos/home-assistant -f values.yaml
```

After making changes to the values file one needs to upgrade the helm chart with the following: 

```bash
helm upgrade home-assistant pajikos/home-assistant -f values.yaml
```

Probably not necessary to do as soon as argocd is set up but whatever lol, good to have it in some readme.



TODO TRY TO DO THIS WITH THIS https://github.com/bjw-s/helm-charts/blob/main/charts/library/common/templates/classes/_rawResource.tpl
