# setting up research environment with ngrok and nix

It is hard to manage remote connections to machines on corporate networks. 
One option is to forward ports through an ssh connection, but this is fragile and cannot be used on an iPad. 
Instead, I use ngrok to forward several interfaces (ssh, RStudio, Jupyter, etc.) to public addresses. 
I don't want to use paid ngrok tiers to get fixed URLs, so I use a telegram bot to obtain most relevant randomly-generated links. 

This Nix flake lets you quickly set up ngrok with ssh and JupyterLab managed with [`jupyenv`](https://github.com/tweag/jupyenv). 
RStudio Server port forwarding is also enabled in the ngrok config, but I don't manage R through Nix at the moment.

Feel free to fork/use/adapt this code to create your own forwarding schemes.

## How to use

1. Install Nix, e.g. with [`nix-installer`](https://zero-to-nix.com/start/install). 

2. Set up [`ngrok`](https://ngrok.com) and obtain a token.

3. Register a telegram bot and obtain a bot token.

4. Clone this repository and edit `flake.nix`, adding your private info to the corresponding attributes.

5. Use `./run` to run the flake.
