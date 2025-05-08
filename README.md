This is a private fork of the [official permify helm charts](https://github.com/Permify/helm-charts)

----

## Updating from the fork

To pull new hotness from the public repo:

```
cd permify-helm-charts
git remote add public https://github.com/Permify/helm-charts.git
git pull public master # Creates a merge commit
git push origin master
```

----

## Creating a New Release

`./release.sh X.Y.Z`

----

## License

[Apache 2.0 License](./LICENSE).
