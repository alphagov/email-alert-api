## Viewing the Sidekiq UI for Email Alert API

We have access to the Sidekiq UI but because Email Alert API doesn't have a
frontend we have to use port forwarding to see it in our live environments.

You'll need to have access to our EKS clusters before you can follow these
instructions. There's [documentation here](https://docs.publishing.service.gov.uk/kubernetes/get-started/access-eks-cluster/#access-a-cluster-that-you-have-accessed-before) on how to do that. This means that
you'll need full production access before you can view the Sidekiq UI.

To view the UI run:

```
kubectl -n apps port-forward deployment/email-alert-api 8080:8080
```

and then navigate to localhost:8080/sidekiq
