"""Bulk-import de lançamentos históricos para o webhook hook-finance.

Lê o token de .token na raiz, monta o text no formato esperado pelo PURCHASE_RE
(Compra no cartão final NNNN, de R$ X,XX, em DD/MM/YY, às HH:MM, em DESC,
aprovada.) e POSTa um por vez no /exec.

Pula linhas sem cartão ou em moeda diferente de BRL.
"""

import json
import urllib.request
import urllib.error
import time
from pathlib import Path

URL = (
    "https://script.google.com/macros/s/"
    "AKfycby7v9mrOGHV6tIaiOmgs7ZaGolmSTXsEKIj3rYjBlYalePcuBmSM0C35Wc5-vJZRNE-7Q"
    "/exec"
)
DEFAULT_TIME = "12:00"
YEAR_SUFFIX = "26"

TXNS = [
    ("14/01", "Porto Seguro Cia Seg", "1018", "164,81"),
    ("20/02", "Barra Smile — Danielle", "0784", "490,00"),
    ("10/03", "Rentcars", "1018", "368,04"),
    ("11/03", "Airbnb * hm2nzf4mhn", "4750", "191,90"),
    ("14/03", "Tradicional", "1018", "163,33"),
    ("15/03", "Mercado*Mercadolivre", "1018", "52,80"),
    ("16/03", "Spg*Conselhoregional", "4750", "177,38"),
    ("17/03", "Spg*Conselhoregional", "4750", "69,39"),
    ("17/03", "Beto Carrero*Beto Ca", "4750", "502,56"),
    ("18/03", "Diegojoaquimvidal", "1018", "73,33"),
    ("19/03", "Peahi - Jacarepagua — Danielle", "0784", "161,55"),
    ("24/03", "On Sportswear", "1018", "674,55"),
    ("27/03", "Peahi - Jacarepagua — Danielle", "0784", "151,70"),
    ("01/04", "Zoo Pomerode", "4750", "31,00"),
    ("01/04", "Alles Park", "4750", "85,50"),
    ("08/04", "Unidas Locadora Fln6", "9727", "103,23"),
    ("09/04", "Beto Carrero World", "1018", "125,30"),
    ("09/04", "Beto Carrero World", "1018", "66,33"),
    ("10/04", "Beto Carrero World", "1018", "67,33"),
    ("11/04", "Alles Park Ecoturism", "1018", "50,00"),
    ("12/04", "Bianca Larica Barbie — Danielle", "0784", "199,30"),
    ("13/04", "Aventura Jurassica", "1018", "54,93"),
    ("14/04", "Dufry do Brasil Duty — Danielle", "0784", "178,09"),
    ("15/04", "Drogarias Pacheco S.", "1018", "61,30"),
    ("23/04", "Ri Happy", "1018", "185,98"),
    ("28/04", "Claude.ai Subscription", "1018", "531,89"),
    ("28/04", "Cashback IOF Férias", "0000", "-9,24"),
    ("28/04", "Anthropic", "1018", "5,00"),
    ("29/04", "Sympla*Personalite Rec", "4750", "403,70"),
    ("29/04", "Hnt Loja - A052 - Freg", "1018", "16,90"),
    ("29/04", "Supermercados Vianense", "1018", "67,38"),
    ("29/04", "Crepelocks Metropolita — Danielle", "0784", "41,58"),
    ("29/04", "Vmt*Mercados — Danielle", "0784", "12,99"),
    ("29/04", "Ri Happy — Danielle", "0784", "7,90"),
    ("30/04", "Ec*Shellbox", "1018", "332,79"),
    ("30/04", "Prezunic 709", "1018", "397,57"),
    ("30/04", "Sem Parar", "9727", "50,00"),
    ("01/05", "Vmt*Mercados", "1018", "23,98"),
    ("01/05", "Picpay*Mundialfregue", "1018", "489,93"),
    ("01/05", "Google Cloud 23v9bs", "4750", "21,64"),
    ("01/05", "V1", "1018", "59,90"),
    ("01/05", "Supermercados Vianense", "1018", "32,78"),
    ("01/05", "Picpay*Mundialfregue", "1018", "447,13"),
]


def main():
    repo = Path(__file__).resolve().parent.parent
    token = (repo / ".token").read_text().strip()

    for i, (date_short, estab, card, value) in enumerate(TXNS, 1):
        date = f"{date_short}/{YEAR_SUFFIX}"
        text = (
            f"Compra no cartão final {card}, de R$ {value}, em {date}, "
            f"às {DEFAULT_TIME}, em {estab}, aprovada."
        )
        payload = json.dumps(
            {"token": token, "title": "Compra aprovada", "text": text},
            ensure_ascii=False,
        ).encode("utf-8")
        req = urllib.request.Request(
            URL, data=payload, headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(req, timeout=30)
            status = "OK"
        except urllib.error.HTTPError as e:
            # 302 follow -> 405 no destino do redirect; o webhook EXECUTOU.
            status = f"sent (HTTP {e.code})"
        except Exception as e:
            status = f"ERR {e}"
        print(f"[{i:2}/{len(TXNS)}] {card} {value:>9} {date}  {estab[:35]:35}  -> {status}")
        time.sleep(0.4)


if __name__ == "__main__":
    main()
