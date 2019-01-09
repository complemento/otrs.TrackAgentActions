package Kernel::System::GenericAgent::ComplementoSetAgentInfoAndDateFields;

use strict;
use warnings;

use Kernel::System::DynamicField;
use Kernel::System::DynamicField::Backend;

# use Kernel::System::Priority;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicFieldBackend',
    'Kernel::System::Ticket',
    'Kernel::System::Time',
);
#Obrigatório:
#Date - Nome do Campo Dinamico onde deve ser armazenado a data e hora (o campo dinamico deve ser do tipo DateTime)

#Um dos dois abaixo obrigatórios, podendo inclusive ser os dois campos:
#AgentLogin - Nome do campo dinâmico onde devemos armazenar o Login do usuário que executou a ação
#AgentFullname - Concatenação do UserFirstname + " " + UserLastname do usuário que executou a ação

#Opcional
#Overwrite - "Yes" (Padrão) e "No". Caso marcado "No" o sistema verifica se o campo dinamico especificado no parametro "Date" já está preenchido. Se já estiver, a execução do módulo é interrompida.

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{DynamicFieldObject}         = $Kernel::OM->Get('Kernel::System::DynamicField');
    $Self->{LogObject}                  = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{TimeObject}                 = $Kernel::OM->Get('Kernel::System::Time');
    $Self->{TicketObject}               = $Kernel::OM->Get('Kernel::System::Ticket');
    $Self->{DynamicFieldBackendObject}  = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}



sub Run {
    my ( $Self, %Param ) = @_;
    
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $UserObject = $Kernel::OM->Get('Kernel::System::User');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
    my $Overwrite = "Yes";

	if ( $Param{New}->{Overwrite} ) {
		$Overwrite = $Param{New}->{Overwrite}
	}
    
    # check needed param
    if ( !$Param{New}->{'Date'} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need Date param for GenericAgent module!',
        );
        return;
    }
    
  
    if (!$Param{New}->{AgentLogin} && !$Param{New}->{AgentFullname}){
            $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need AgentLogin  or AgentFullname  param for GenericAgent module!',
        );
        return;
	
    }
    

    #INFORMAÇÔES DO CHAMADO

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

	

    # get ticket data
    my %Ticket = $TicketObject->TicketGet(
        %Param,
        DynamicFields => 0,
    );

#Preenchimento do Campo  ChangeBy
#$VAR65 = 'ChangeBy';
#$VAR66 = '1';
    my $ChangeID = $Ticket{ChangeBy};
    my %User;

	if($TicketObject->TicketCheckForProcessType(
        TicketID => $Ticket{TicketID},
    )){

		my $DynamicFieldChangedBy = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
			Name => 'ProcessManagementUserChangeID'
		);

		$ChangeID = $DynamicFieldBackendObject->ValueGet(
			DynamicFieldConfig => $DynamicFieldChangedBy,      # complete config of the DynamicField
			ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
															# must be linked to, e. g. TicketID
		);


	} 

    if($ChangeID){
	 %User = $UserObject->GetUserData(
         	UserID => $ChangeID,
    	);


	#Preenchimento da Data

	my $DynamicFieldDate = $DynamicFieldObject->DynamicFieldGet(
		Name => $Param{New}->{Date},
	);
	if($Overwrite eq "Yes"){
		my $Success = $DynamicFieldBackendObject->ValueSet(
			DynamicFieldConfig => $DynamicFieldDate,      # complete config of the DynamicField
			 ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                               # must be linked to, e. g. TicketID
			 Value              => $TimeObject->CurrentTimestamp()  ,                   # Value to store, depends on backend type
			 UserID             => 1,
		);
	

		#Preenchimento do Campo Login
		if ($Param{New}->{AgentLogin}){
			my $DynamicFieldAgentLogin = $DynamicFieldObject->DynamicFieldGet(
				Name => $Param{New}->{'AgentLogin'},
			);
			my $Success = $DynamicFieldBackendObject->ValueSet(
				 DynamicFieldConfig => $DynamicFieldAgentLogin,      # complete config of the DynamicField
				 ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                                # must be linked to, e. g. TicketID
				 Value              => $User{UserLogin},                   # Value to store, depends on backend type
				 UserID             => 1,
			 );


		}
		#Preenchimento do Campo FullName
		if ($Param{New}->{AgentFullname}){
			my $DynamicFieldAgentFullname = $DynamicFieldObject->DynamicFieldGet(
        			Name => $Param{New}->{'AgentFullname'},
  	        	);
			my $Success = $DynamicFieldBackendObject->ValueSet(
    				DynamicFieldConfig => $DynamicFieldAgentFullname,      # complete config of the DynamicField
		       		ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
                                                        # must be linked to, e. g. TicketID
		       		Value              => $User{UserFirstname} . "  " . $User{UserLastname}  ,                   # Value to store, depends on backend type
		       		UserID             => 1,
	         	);


		
		}

	}else{
		#Preenchimento da Data
		my $ValueDate = $DynamicFieldBackendObject->ValueGet(
			DynamicFieldConfig => $DynamicFieldDate,      # complete config of the DynamicField
			ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                               # must be linked to, e. g. TicketID
		);
		if(!$ValueDate){
			my $Success = $DynamicFieldBackendObject->ValueSet(
				DynamicFieldConfig => $DynamicFieldDate,      # complete config of the DynamicField
				 ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
			                                        # must be linked to, e. g. TicketID
				 Value              => $TimeObject->CurrentTimestamp()  ,                   # Value to store, depends on backend type
				 UserID             => 1,
			 );
		}
		#Preenchimento do Campo Login
	        if ($Param{New}->{AgentLogin}){
			my $DynamicFieldAgentLogin = $DynamicFieldObject->DynamicFieldGet(
				Name => $Param{New}->{'AgentLogin'},
			);
			
			
			my $ValueLogin = $DynamicFieldBackendObject->ValueGet(
				DynamicFieldConfig => $DynamicFieldDate,      # complete config of the DynamicField
				ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                               # must be linked to, e. g. TicketID
			);
			if(!$ValueLogin){
				my $Success = $DynamicFieldBackendObject->ValueSet(
					DynamicFieldConfig => $DynamicFieldAgentLogin,      # complete config of the DynamicField
					ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                                # must be linked to, e. g. TicketID
					Value              => $User{UserLogin},                   # Value to store, depends on backend type
					UserID             => 1,
			 	);
			}


		
		}
		if ($Param{New}->{AgentLogin}){
			my $DynamicFieldAgentLogin = $DynamicFieldObject->DynamicFieldGet(
				Name => $Param{New}->{'AgentLogin'},
			);
			my $ValueAgentFullname = $DynamicFieldBackendObject->ValueGet(
				DynamicFieldConfig => $DynamicFieldAgentLogin,      # complete config of the DynamicField
				ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
				                               # must be linked to, e. g. TicketID
			);
			if(!$ValueAgentFullname){
				my $Success = $DynamicFieldBackendObject->ValueSet(
    					DynamicFieldConfig => $DynamicFieldAgentLogin,      # complete config of the DynamicField
		       			ObjectID           => $Ticket{TicketID},                # ID of the current object that the field
                                                        # must be linked to, e. g. TicketID
		       			Value              => $User{UserFirstname} . "  " . $User{UserLastname}  ,                   # Value to store, depends on backend type
		       			UserID             => 1,
	         		);
			}

		}
	}
	
	

    }

				
    
	
       
 
}

1;
