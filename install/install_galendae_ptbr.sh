#!/usr/bin/env bash

set -e  # Encerra se qualquer comando falhar

REPO_URL="https://github.com/chris-marsh/galendae.git"
INSTALL_DIR="$HOME/dev/galendae"  # Altere se quiser
BIN_DEST="/usr/local/bin/galendae"

echo "📦 Clonando repositório..."
rm -rf "$INSTALL_DIR"
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "📝 Aplicando tradução para português..."

# Tradução dos dias e meses
sed -i 's/"Sunday", "Su"/"Domingo", "Dom"/;
         s/"Monday", "Mo"/"Segunda", "Seg"/;
         s/"Tuesday", "Tu"/"Terça", "Ter"/;
         s/"Wednesday", "We"/"Quarta", "Qua"/;
         s/"Thursday", "Th"/"Quinta", "Qui"/;
         s/"Friday", "Fr"/"Sexta", "Sex"/;
         s/"Saturday", "Sa"/"Sábado", "Sab"/' src/gui.c

sed -i 's/"January"/"Janeiro"/;
         s/"February"/"Fevereiro"/;
         s/"March"/"Março"/;
         s/"April"/"Abril"/;
         s/"May"/"Maio"/;
         s/"June"/"Junho"/;
         s/"July"/"Julho"/;
         s/"August"/"Agosto"/;
         s/"September"/"Setembro"/;
         s/"October"/"Outubro"/;
         s/"November"/"Novembro"/;
         s/"December"/"Dezembro"/' src/gui.c

# Tradução da ajuda
sed -i '/puts("USAGE")/,+15 {
    s/USAGE/USO/;
    s/DESCRIPTION/DESCRIÇÃO/;
    s/displays a gui calendar. Keys:/exibe um calendário gráfico. Teclas:/;
    s/decrease month/diminuir mês/;
    s/increase month/aumentar mês/;
    s/increase year/aumentar ano/;
    s/decrease year/diminuir ano/;
    s/return to current date/voltar à data atual/;
    s/exit the calendar/sair do calendário/;
    s/OPTIONS/OPÇÕES/;
    s/config file to load/arquivo de configuração/;
    s/display this help/mostrar esta ajuda/;
    s/output version/mostrar a versão/
}' src/main.c

echo "🛠️  Compilando..."
make clean
make release

echo "🚀 Instalando..."
sudo install -Dm755 galendae "$BIN_DEST"

echo "✅ Galendae traduzido instalado com sucesso em $BIN_DEST"
