export const PROPOSTA = {
  intro:
    "Nossa proposta tem como objetivo não apenas atender a demanda de jardinagem e paisagismo, limpeza e conservação, mas criar uma parceria com o cliente e agregar qualidade de vida aos moradores. Atuamos no mercado tendo realizado projetos personalizados que buscam atender os conceitos de conforto, funcionalidade e estética de acordo com as características e necessidades de cada cliente. Trabalhamos com projetos paisagísticos, reformas e manutenção de jardins, podas de árvores e arbustos, projetos ornamentais, entre outros. Acreditamos e confiamos em nosso desempenho, e por isso ofertamos garantia total e satisfação completa.",

  referencias: [
    { condo: "Condomínio Residencial Quinta do Moinho", sindico: "Síndico Hélio Vidilino — (11) 94037-7744" },
    { condo: "Condomínio Residencial Quinta do Loureiro", sindico: "Síndico Tiago Mello — (11) 96149-8089" },
    { condo: "Condomínio dos Girassóis", sindico: "Síndico Thiago Maiellaro — (11) 99694-4188" },
  ],

  manutencao: [
    "Roçagem de gramas no padrão de 3 a 5 cm de altura, para que a raiz da grama não seja atingida pelo nylon; dessa forma ajuda na forração da grama e não deixa buracos que deem espaço para a erva daninha crescer;",
    "Poda de arbustos seguindo formato;",
    "Poda de pequenas árvores (poda de limpeza);",
    "Corte de grama dos taludes e área externa;",
    "Mão de obra para plantar mudas de árvores e plantas, ou substituição caso seja necessário;",
    "Coroamento e descompactação do solo onde há plantas;",
    "Mão de obra para criação de novas áreas paisagísticas;",
    "Mão de obra para controle de pragas com produto herbicida seletivo, aplicado com bomba de pulverizar (produto fornecido pelo cliente);",
    "Mão de obra para adubação, tanto com terra via solo quanto via foliar com pulverizador;",
    "Limpeza e remoção dos resíduos (saco de lixo por conta do cliente).",
  ],

  supervisao:
    "Auxílio do supervisor para a orientação dos serviços a serem realizados e para acompanhar os serviços que estão em andamento.",

  condicoesPagamento:
    "O pagamento será efetivado sempre 5 (cinco) dias após o serviço realizado, mediante a apresentação de nota fiscal.",

  agradecimento: "Aguardamos seu breve retorno e agradecemos a atenção.",
};

/**
 * Modelos de escopo (II. Execução do Serviço) — textos fixos, selecionáveis.
 * Para adicionar um novo modelo, basta acrescentar uma entrada aqui.
 */
export interface ModeloEscopo {
  label: string;
  execucao: string[];
}

export const ESCOPOS: Record<string, ModeloEscopo> = {
  completo: {
    label: "Completo · 2 visitas/mês, equipe de 7 + jardineiro",
    execucao: [
      "2 visitas mensais com equipe de 7 pessoas, dividida em duas partes: 1ª visita — parte de cima: corte de grama, poda de arbustos e limpeza; 2ª visita — parte de baixo e externa do condomínio: poda de arbustos, corte de grama e limpeza.",
      "2 visitas mensais de 1 jardineiro para limpeza de canteiros e supervisão geral. Essa visita é agendada (segunda a sexta-feira); na semana da visita individual não haverá visita da equipe.",
    ],
  },
  padrao: {
    label: "Padrão · visita mensal, equipe de 5 a 6",
    execucao: [
      "Visita mensal com equipe de 5 a 6 pessoas para corte de grama, poda de arbustos e limpeza.",
    ],
  },
};

export const ESCOPO_PADRAO = "completo";

/** Lista para popular o seletor no formulário. */
export const ESCOPO_OPCOES = Object.entries(ESCOPOS).map(([valor, m]) => ({ valor, label: m.label }));
