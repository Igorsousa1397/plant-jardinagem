#!/usr/bin/env bash
# Plant Jardinagem — adiciona 'Cinto talabarte' aos EPIs
set -e
if [ ! -f package.json ]; then echo "Rode na raiz do projeto."; exit 1; fi
echo "Atualizando EPIs..."

cat > "src/lib/constants.ts" <<'__PLANT_EOF__'
import type { Status } from "@/types";

export const SERVICOS = [
  "Corte e Poda",
  "Remoção de Folhas / Galhos",
  "Paisagismo",
  "Limpeza Geral do Jardim",
  "Adubação",
  "Controle de pragas",
];

export const EQUIPAMENTOS = [
  "Roçadeira",
  "Soprador",
  "Rastelo",
  "Tesoura de Poda",
  "Tesoura de Cerca Viva",
];

export const EPIS = ["Luvas", "Botas", "Óculos de Proteção", "Cinto talabarte"];

export const CONDOS = [
  "Alameda das Palmeiras",
  "San Denis",
  "Quinta do Moinho",
  "Quinta do Loureiro",
  "dos Girassóis",
];

// Classes literais para o JIT do Tailwind capturar
export const STATUS_STYLES: Record<Status, string> = {
  "Finalizado": "bg-sucessoBg text-sucesso",
  "Em andamento": "bg-atencaoBg text-atencao",
  "Agendado": "bg-infoBg text-info",
  "Atrasado": "bg-erroBg text-erro",
};

export const EMPRESA = {
  nome: "Plant Jardinagem e Paisagismo",
  prestador: "Plant Jardinagem - Manutenção e Paisagismo / Claiton",
  cnpj: "42.704.559/0001-42",
  telefone: "(11) 97179-2236",
  whatsapp: "5511971792236",
  email: "plantjardinagem@gmail.com",
  instagram: "@plantjardinagem",
  endereco: "Av. Benedito de Andrade, 358 - Pereira Barreto - São Paulo",
};
__PLANT_EOF__
echo "  ok  src/lib/constants.ts"
echo "Feito. Reinicie o npm run dev (ou commit + push)."
