export type Status = "Finalizado" | "Em andamento" | "Agendado" | "Atrasado";

export interface Report {
  id: string;
  condo: string;
  data: string;
  duracao: string;
  status: Status;
  servicos: string[];
  equipamentos: string[];
  epi: string[];
  observacoes: string;
  proximaVisita: string;
  fotosAntes: string[];
  fotosDepois: string[];
  arquivado?: boolean;
}

export interface Cliente {
  id: string;
  nome: string;
  sindico?: string;
  telefone?: string;
}

export interface Agendamento {
  id: string;
  clienteId?: string;
  condo: string;
  data: string;        // dd/mm/aaaa
  observacao: string;
}

export type Papel = "admin" | "funcionario";
