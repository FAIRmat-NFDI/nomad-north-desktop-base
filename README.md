# nomad-north-desktop-base 

This docker image can be used for desktop based applications in NOMAD Remote Tool Hub (NORTH) environment.

## Getting Started
You can then run container using this image with the following command:

```bash
docker run -it -p 8888:8888 ghcr.io/fairmat-nfdi/nomad-north-desktop-base:main
```

## Integration

When using this image with JupyterHub, you can set the `default_url` [parameter](https://jupyterhub.readthedocs.io/en/latest/reference/api/spawner.html#jupyterhub.spawner.Spawner.default_url) of the spawner to point to the remote desktop interface. For example:

```
default_url = "/desktop/"
```
This will make the remote desktop interface the default view when users log in to JupyterHub.


## Naming convention

You can chech all available images in the [GitHub Packages](https://github.com/orgs/FAIRmat-NFDI/packages?repo_name=nomad-north-desktop-base).
For every stable release there is a corresponding tag which matches with the version of the tag name of the base-notebook ([Jupyter Docker Stacks's image](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-base-notebook)).


## Additional Resources

- [jupyter-remote-desktop-proxy](https://github.com/jupyterhub/jupyter-remote-desktop-proxy)
- [Dockerfile](https://github.com/jupyterhub/jupyter-remote-desktop-proxy/blob/main/Dockerfile)

