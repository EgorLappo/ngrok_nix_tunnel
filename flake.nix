
{
  description = "setup the tunnels from my lab machine";
  nixConfig.bash-prompt = "\[python\]$ ";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.jupyenv.url = "github:tweag/jupyenv";

  outputs = inputs @ { self, nixpkgs, flake-utils, jupyenv, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            
            ngrok_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            telegram_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            telegram_id = "00000000";
            jupyter_password = "password"; 

            inherit (jupyenv.lib.${system}) mkJupyterlabNew;
            jupyterlab = mkJupyterlabNew ({...}: {
                nixpkgs = inputs.nixpkgs;
                imports = [ (import ./jupy_kernels.nix)];
            });

            python = pkgs.python3.withPackages (ps: with ps; [ requests pytelegrambotapi ]);

            script = pkgs.writeShellScriptBin "run_ngrok" ''
                #!${pkgs.stdenv.shell}
                export PATH=${pkgs.lib.makeBinPath [ pkgs.ngrok ]}:$PATH
                
                trap 'kill $(jobs -p) 2>/dev/null' EXIT

                ngrok start --all --config ${ngrok_config} --log-level crit &
                ${python}/bin/python ${telegramBot} & 
                ${jupyterlab}/bin/jupyter-lab -y --no-browser --config=${jupyter_config} 
                '';

            jupyter_config = pkgs.writeTextFile {
                name = "jupyter_config.py";
                text = ''
                    c.ServerApp.ip = '*'
                    c.ServerApp.allow_remote_access = True
                    c.ServerApp.port = 8888
                    c.ServerApp.token = '${jupyter_password}'
                '';
            };

            ngrok_config = pkgs.writeTextFile {
                name = "ngrok_conf.yml";
                text = ''
                    version: "2"
                    authtoken: ${ngrok_token}

                    tunnels:
                        rstudio:
                            addr: 8787
                            proto: http

                        ssh:
                            addr: 22
                            proto: tcp

                        jupyterlab:
                            addr: 8888
                            proto: http
                '';
            };

            telegramBot = pkgs.writeTextFile {
                name = "telegram_bot.py";
                text = ''
                    import json
                    import requests
                    import telebot as tg

                    token = '${telegram_token}'
                    my_uid = '${telegram_id}'

                    bot = tg.TeleBot(token)


                    @bot.message_handler(commands=['start'])
                    def start_message(message):
                        uid = str(message.chat.id)

                        if uid == my_uid:
                            bot.send_message(
                                message.chat.id, 'type /links to get current ngrok urls')
                        else:
                            bot.send_message(
                                message.chat.id, 'you are not authorized to use this bot')


                    @bot.message_handler(commands=['links'])
                    def send_links(message):
                        uid = str(message.chat.id)

                        if uid == my_uid:
                            # get ngrok urls
                            r = requests.get('http://localhost:4040/api/tunnels')
                            tunnels = json.loads(r.text)

                            # get tunnel public urls
                            urls = {tunnel['name']: tunnel['public_url']
                                    for tunnel in tunnels['tunnels']}

                            bot.send_message(message.chat.id, 'here are the currently active tunnels:\n\n' +
                                            '\n'.join([name + ': ' + url for name, url in urls.items()]))
                        else:
                            bot.send_message(
                                message.chat.id, 'you are not authorized to use this bot')


                    bot.infinity_polling()
                '';
            };
        in
        {
            defaultPackage = script; 
        }
      );
}