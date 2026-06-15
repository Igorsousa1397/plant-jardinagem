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

export const EPIS = ["Luvas", "Botas", "Óculos de Proteção"];

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
  cnpj: "42.704.559/0001-42",
  telefone: "(11) 97179-2236",
  whatsapp: "5511971792236",
  email: "plantjardinagem@gmail.com",
};
