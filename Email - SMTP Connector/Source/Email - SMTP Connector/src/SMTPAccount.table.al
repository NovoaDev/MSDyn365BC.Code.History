// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Holds the information for all e-mail accounts that are registered via the SMTP connector
/// </summary>
table 4511 "SMTP Account"
{
    Access = Internal;

    Caption = 'SMTP Account';

    fields
    {
        field(1; "Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }

        field(2; Name; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Name of account';
        }

        field(3; "Server"; Text[250])
        {
            DataClassification = CustomerContent;
        }

        field(4; Authentication; Enum "SMTP Authentication")
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec.Authentication = Rec.Authentication::Basic then
                    exit;
                Rec."User Name" := '';
                SetPassword('');
            end;
        }

        field(5; "User Name"; Text[250])
        {
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                Rec."User Name" := DelChr(Rec."User Name", '<>', ' ');
                if Rec."User Name" = '' then
                    exit;
                TestField(Rec.Authentication, Rec.Authentication::Basic.AsInteger());
            end;
        }

        field(6; "Server Port"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'SMTP Server Port';
            InitValue = 25;
        }

        field(7; "Secure Connection"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = false;
        }

        field(8; "Password Key"; Guid)
        {
            DataClassification = SystemMetadata;
        }

        field(10; "Email Address"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Email Address';

            trigger OnValidate()
            var
                EmailAccount: Codeunit "Email Account";
            begin
                EmailAccount.ValidateEmailAddress(Rec."Email Address");
            end;
        }

        field(11; "Sender Name"; Text[250])
        {
            DataClassification = CustomerContent;
        }

        field(12; "Created By"; Text[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    var
        UnableToGetPasswordMsg: Label 'Unable to get SMTP Account password';
        UnableToSetPasswordMsg: Label 'Unable to set SMTP Account password';

    trigger OnDelete()
    begin
        if not IsNullGuid(Rec."Password Key") then
            if IsolatedStorage.Delete(Rec."Password Key") then;
    end;

    procedure SetPassword(Password: Text)
    begin
        if IsNullGuid(Rec."Password Key") then
            Rec."Password Key" := CreateGuid();

        if not IsolatedStorage.Set(Format(Rec."Password Key"), Password, DataScope::Company) then
            Error(UnableToSetPasswordMsg);
    end;

    [NonDebuggable]
    procedure GetPassword(PasswordKey: Guid) Password: Text
    begin
        if not IsolatedStorage.Get(Format(PasswordKey), DataScope::Company, Password) then
            Error(UnableToGetPasswordMsg);
    end;
}